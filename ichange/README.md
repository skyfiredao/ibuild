ichange tools
======

#### itrack.sh
stand-alone tool, tracking gerrit stream-events and save it as json in allow host from conf

#### json2svn.sh
non-stand-alone tool, convert gerrit stream-events json file to svn:ichange by itrack.sh

#### sort_patch.sh
stand-alone tool, list 24 hours patch from svn:ichange

Usage: sort_patch.sh <YYYYMMDD> <gerrit server doamin name> <project/branch>

#### conf/HOSTNAME.conf
config file for itrack: 

GERRIT_SRV_LIST=<gerrit1 gerrit2>

DOMAIN_NAME=<your domain.com>

GERRIT_SRV_PORT=<29418>

GERRIT_ROBOT=<login account>

GERRIT_XML_URL=<manifest path>

GERRIT_BRANCH=<branch name>

ICHANGE_SVN_SRV=<svn:icahnge URL>

ICHANGE_SVN_OPTION=<svn option>

