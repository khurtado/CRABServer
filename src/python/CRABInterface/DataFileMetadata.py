import logging
import time
import commands
import json
from ast import literal_eval

# WMCore dependecies here
from WMCore.REST.Error import InvalidParameter, ExecutionError, MissingObject

from CRABInterface.Utils import getDBinstance

class DataFileMetadata(object):
    @staticmethod
    def globalinit(dbapi, config):
        DataFileMetadata.api = dbapi
        DataFileMetadata.config = config

    def __init__(self, config):
        self.logger = logging.getLogger("CRABLogger.DataFileMetadata")
        self.FileMetaData = getDBinstance(config,'FileMetaDataDB','FileMetaData')

    def getFiles(self, taskname, filetype):
        self.logger.debug("Calling jobmetadata for task %s and filetype %s" % (taskname, filetype))
        binds = {'taskname': taskname, 'filetype': filetype}
        rows = self.api.query(None, None, self.FileMetaData.GetFromTaskAndType_sql, **binds)
        for row in rows:
            yield {'taskname': taskname,
                   'filetype': filetype,
                   'pandajobid': row[0],
                   'outdataset': row[1],
                   'acquisitionera': row[2],
                   'swversion': row[3],
                   'inevents': row[4],
                   'globaltag': row[5],
                   'publishname': row[6],
                   'location': row[7],
                   'tmplocation': row[8],
                   'runlumi': literal_eval(row[9].read()),
                   'adler32': row[10],
                   'cksum': row[11],
                   'md5': row[12],
                   'lfn': row[13],
                   'filesize': row[14],
                   'parents': literal_eval(row[15].read()),
                   'state': row[16],
                   'created': str(row[17]),
                   'tmplfn': row[18]}

    def inject(self, *args, **kwargs):
        self.logger.debug("Calling jobmetadata inject with parameters %s" % kwargs)

        bindnames = set(kwargs.keys()) - set(['outfileruns', 'outfilelumis'])
        binds = {}
        for name in bindnames:
            binds[name] = [str(kwargs[name])]
        binds['runlumi'] = [str(dict(zip(map(str, kwargs['outfileruns']), [map(str, lumilist.split(',')) for lumilist in kwargs['outfilelumis']])))]

        # Duplicating values. oracle is not bounding variables from dictionary
        binds['taskname_unq'] = binds['taskname']
        binds['outlfn_unq'] = binds['outlfn']
        binds['outtmplocation_upd'] = binds['outtmplocation']
        binds['outsize_upd'] = binds['outsize']
        self.api.modifynocheck(self.FileMetaData.New_sql, **binds)
        return []

    def changeState(self, *args, **kwargs):#kwargs are (taskname, outlfn, filestate)
        self.logger.debug("Changing state of file %(outlfn)s in task %(taskname)s to %(filestate)s" % kwargs)

        self.api.modify(self.FileMetaData.ChangeFileState_sql, **dict((k, [v]) for k,v in kwargs.iteritems()))

    def delete(self, taskname, hours):
        if taskname:
            self.logger.debug("Deleting all the files associated to task: %s" % taskname)
            self.api.modifynocheck(self.FileMetaData.DeleteTaskFiles_sql, taskname=[taskname])
        if hours:
            self.logger.debug("Deleting all the files older than %s hours" % hours)
            self.api.modifynocheck(self.FileMetaData.DeleteFilesByTime_sql, hours=[hours])
