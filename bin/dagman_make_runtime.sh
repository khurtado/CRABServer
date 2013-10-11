#! /bin/sh

set -x
set -e
BASEDIR=$(cd "$(dirname "$0")"; pwd)

ORIGDIR=$PWD
STARTDIR=$PWD/tmp/runtime

# Allow overriding the output filename
if [[ "X" == "X$CRAB3_VERSION" ]]; then 
    CRAB3_VERSION=3.0.0-pre7
fi

WMCOREDIR=$STARTDIR/WMCore
WMCOREVER=0.9.70-dagman2
WMCOREREPO=bbockelm

TASKWORKERDIR=$STARTDIR/TaskWorker
TASKWORKERVER=0.0.1pre3-dagman5
TASKWORKERREPO=bbockelm

CAFUTILITIESDIR=$STARTDIR/CAFUtilities
CAFUTILITIESVER=0.0.1pre4-dagman
CAFUTILITIESREPO=bbockelm

DBSDIR=$STARTDIR/DBS
DBSVER=DBS_2_1_9-dagman2
DBSREPO=bbockelm

DLSDIR=$STARTDIR/DLS
DLSVER=DLS_1_1_3
DLSREPO=bbockelm

CRABSERVERDIR=$STARTDIR/CRABServer
CRABSERVERVER=3.2.0pre2-dagman3
CRABSERVERREPO=bbockelm

CRABCLIENTDIR=$STARTDIR/CRABClient
CRABCLIENTVER=3.2.0pre2-dagman3
CRABCLIENTREPO=bbockelm
[[ -d $STARTDIR ]] || mkdir -p $STARTDIR

cp $BASEDIR/gWMS-CMSRunAnalysis.sh $STARTDIR || exit 3


rm -rf $WMCOREDIR && mkdir -p $WMCOREDIR
rm -rf $TASKWORKERDIR && mkdir -p $TASKWORKERDIR
rm -rf $DBSDIR && mkdir -p $DBSDIR
rm -rf $DLSDIR && mkdir -p $DLSDIR
rm -rf $CRABSERVERDIR && mkdir -p $CRABSERVERDIR
rm -rf $CRABCLIENTDIR && mkdir -p $CRABCLIENTDIR

if [[ -n "$CRAB_OVERRIDE_SOURCE" ]]; then 
    REPLACEMENT_ABSOLUTE=$(readlink -f $CRAB_OVERRIDE_SOURCE)
elif [[ "x$1" != "x" ]]; then
    REPLACEMENT_ABSOLUTE=$(readlink -f $1)
else
    REPLACEMENT_ABSOLUTE=""
fi
# blow away old directories
rm -rf $STARTDIR/*/
pushd $STARTDIR


if [[ ! -e external+py2-pyopenssl+0.11-1-1.slc5_amd64_gcc462.rpm ]]; then
    curl -L http://cmsrep.cern.ch/cmssw/cms/RPMS/slc5_amd64_gcc462/external+py2-pyopenssl+0.11-1-1.slc5_amd64_gcc462.rpm > external+py2-pyopenssl+0.11-1-1.slc5_amd64_gcc462.rpm || exit 2
fi
rpm2cpio external+py2-pyopenssl+0.11-1-1.slc5_amd64_gcc462.rpm | cpio -uimd || exit 2

if [[ -d "$REPLACEMENT_ABSOLUTE/CAFUtilities" ]]; then
    echo "Using replacement CAFUtlities source at $REPLACEMENT_ABSOLUTE/CAFUtlities"
    CAFUTILITIES_PATH="$REPLACEMENT_ABSOLUTE/CAFUtilities"
else
    curl -L https://github.com/$CAFUTILITIESREPO/CAFUtilities/archive/$CAFUTILITIESVER.tar.gz | tar zx || exit 2
    CAFUTILITIES_PATH="CAFUtilities-$CAFUTILITIESVER"
fi

if [[ -d "$REPLACEMENT_ABSOLUTE/WMCore" ]]; then
    echo "Using replacement WMCore source at $REPLACEMENT_ABSOLUTE/WMCore"
    WMCORE_PATH="$REPLACEMENT_ABSOLUTE/WMCore"
else
    if [[ ! -e $WMCOREVER.tar.gz ]]; then
        curl -L https://github.com/$WMCOREREPO/WMCore/archive/$WMCOREVER.tar.gz > $WMCOREVER.tar.gz || exit 2
    fi
    tar zxf $WMCOREVER.tar.gz || exit 2
    WMCORE_PATH="WMCore-$WMCOREVER"
fi

if [[ -d "$REPLACEMENT_ABSOLUTE/CAFTaskWorker" ]]; then
    echo "Using replacement CAFTaskWorker source at $REPLACEMENT_ABSOLUTE/CAFTaskWorker"
    TASKWORKER_PATH="$REPLACEMENT_ABSOLUTE/CAFTaskWorker"
else
    curl -L https://github.com/$TASKWORKERREPO/CAFTaskWorker/archive/$TASKWORKERVER.tar.gz | tar zx || exit 2
    TASKWORKER_PATH="CAFTaskWorker-$TASKWORKERVER"
fi

if [ ! -e $DBSVER.tar.gz ]; then
    curl -L https://github.com/$DBSREPO/DBS/archive/$DBSVER.tar.gz > $DBSVER.tar.gz || exit 2
fi
tar zxf $DBSVER.tar.gz || exit 2

if [[ ! -e dls.tar.gz ]]; then
    curl -L https://github.com/$DLSREPO/DLS/archive/$DLSVER.tar.gz > dls.tar.gz || exit 2
fi
tar zxf dls.tar.gz || exit 2

if [[ -d "$REPLACEMENT_ABSOLUTE/CRABServer" ]]; then
    echo "Using replacement CRABServer source at $REPLACEMENT_ABSOLUTE/CRABServer"
    CRABSERVER_PATH="$REPLACEMENT_ABSOLUTE/CRABServer"
else
    curl -L https://github.com/$CRABSERVERREPO/CRABServer/archive/$CRABSERVERVER.tar.gz | tar zx || exit 2
    CRABSERVER_PATH="CRABServer-$CRABSERVERVER"
fi

if [[ -d "$REPLACEMENT_ABSOLUTE/CRABClient" ]]; then
    echo "Using replacement CRABClient source at $REPLACEMENT_ABSOLUTE/CRABClient"
    CRABCLIENT_PATH="$REPLACEMENT_ABSOLUTE/CRABClient"
else
    curl -L https://github.com/$CRABCLIENTREPO/CRABClient/archive/$CRABCLIENTVER.tar.gz | tar zx || exit 2
    CRABCLIENT_PATH="CRABClient-$CRABCLIENTVER"
fi

if [[ ! -e httplib2.tar.gz ]]; then
    curl -L https://httplib2.googlecode.com/files/httplib2-0.8.tar.gz > httplib2.tar.gz || exit 2
fi
if [[ ! -e cherrypy.tar.gz ]]; then
    curl -L http://download.cherrypy.org/cherrypy/3.2.2/CherryPy-3.2.2.tar.gz > cherrypy.tar.gz || exit 2
fi
if [[ ! -e sqlalchemy.tar.gz ]]; then
    curl -L https://pypi.python.org/packages/source/S/SQLAlchemy/SQLAlchemy-0.8.0.tar.gz > sqlalchemy.tar.gz || exit 2
fi
if [[ ! -e crab3-condor-libs.tar.gz ]]; then
    curl -L http://hcc-briantest.unl.edu/CRAB3-condor-libs.tar.gz > crab3-condor-libs.tar.gz || exit 2
fi
tar xzf httplib2.tar.gz || exit 2
tar xzf cherrypy.tar.gz || exit 2
tar xzf sqlalchemy.tar.gz || exit 2
tar xzf crab3-condor-libs.tar.gz *.so* || exit 2

pushd $WMCORE_PATH/src/python
zip -rq $STARTDIR/CRAB3.zip WMCore PSetTweaks -x \*.pyc -x \*.swp || exit 3
popd

pushd $TASKWORKER_PATH/src/python
zip -rq $STARTDIR/CRAB3.zip TaskWorker  -x \*.pyc -x \*.swp || exit 3
popd

pushd $CAFUTILITIES_PATH/src/python
zip -rq $STARTDIR/CRAB3.zip transform Databases PandaServerInterface.py  -x \*.pyc || exit 3
popd

pushd DBS-$DBSVER/Clients/Python
zip -rq $STARTDIR/CRAB3.zip DBSAPI  -x \*.pyc || exit 3
popd

pushd DLS-$DLSVER/Client/LFCClient
zip -rq $STARTDIR/CRAB3.zip *.py  -x \*.pyc || exit 3
popd

pushd $CRABCLIENT_PATH/src/python
zip -rq $STARTDIR/CRAB3.zip CRABClient  -x \*.pyc || exit 3
cp ../../bin/crab $STARTDIR/
cp ../../bin/crab3 $STARTDIR/
popd

pushd $CRABSERVER_PATH/src/python
zip -rq $STARTDIR/CRAB3.zip CRABInterface  -x \*.pyc || exit 3
popd

pushd httplib2-0.8/python2
zip -rq $STARTDIR/CRAB3.zip httplib2  -x \*.pyc || exit 3
popd

pushd CherryPy-3.2.2/
zip -rq $STARTDIR/CRAB3.zip cherrypy  -x \*.pyc || exit 3
popd

pushd opt/cmssw/slc5_amd64_gcc462/external/py2-pyopenssl/0.11/lib/python2.6/site-packages
rm -rf $STARTDIR/lib/python/OpenSSL
mv OpenSSL $STARTDIR/lib/python/
popd

cat > setup.sh << EOF
export CRAB3_VERSION=$CRAB3_VERSION
export CRAB3_BASEPATH=\`dirname \${BASH_SOURCE[0]}\`
export CRAB3_BASEPATH=\`readlink -e \$CRAB3_BASEPATH\`
export PATH=\$CRAB3_BASEPATH:\$PATH
export PYTHONPATH=\$CRAB3_BASEPATH/CRAB3.zip:\$CRAB3_BASEPATH/lib/python:\$PYTHONPATH
export LD_LIBRARY_PATH=\$CRAB3_BASEPATH/lib:\$CRAB3_BASEPATH/lib/condor:\$LD_LIBRARY_PATH
if [ "x\$CONDOR_CONFIG" = "x" ] && [ ! -e /etc/condor/condor_config ] && [ ! -e \$HOME/.condor/condor_config ];
then
  export CONDOR_CONFIG=\$CRAB3_BASEPATH/lib/fake_condor_config
fi
EOF

touch lib/fake_condor_config

mkdir -p bin
cp $CRABSERVER_PATH/bin/* bin/
cp $CAFUTILITIES_PATH/src/python/transformation/CMSRunAnalysis/CMSRunAnalysis.sh bin/
cp $CAFUTILITIES_PATH/src/python/transformation/CMSRunAnalysis/CMSRunAnalysis.py .
cp $CAFUTILITIES_PATH/src/python/transformation/TweakPSet.py .

echo "Making TaskManagerRun tarball"
tar zcf $ORIGDIR/TaskManagerRun-$CRAB3_VERSION.tar.gz CRAB3.zip setup.sh crab3 crab gWMS-CMSRunAnalysis.sh CMSRunAnalysis.py bin TweakPSet.py || exit 4
echo "Making CRAB3 client install"
# removed the gWMS-CMSRunAnalysis tarball
tar zcf $ORIGDIR/CRAB3-gWMS.tar.gz CRAB3.zip setup.sh crab3 crab bin lib || exit 4

popd
