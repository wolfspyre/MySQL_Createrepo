#!/bin/bash
#script to get rh MySQL packages from Oracle
#v0.8
#
# By Default. This script will not provide any output if things work properly.
# to see what's going on. add a numeric verbosity indicator after the script:
# ./updatemysql.sh 
#    will be silent
# ./updatemysql.sh 1
#    will provide some output.. Higher numbers will provide more verbosity.
#
#
#Copyright 2012 Datapipe
#  Wolf Noble <wnoble@datapipe.com>
#
GET5=true
GET6=true
GETx86_64=true
GETi386=false
GET51=true
GET55=true
GET56=true
UPDATEREPO=true
ARCHIVEONLY=false
TOPDIR="/repo/vendor/mysql"
export TOPDIR
export UPDATEREPO
debug=0;
if [ -n "${1:+1}" ]; then debug=$1; else debug=0; fi
export TEMPFILE FILE GET64 GET32 debug
preReqs() {
  #make sure required binaries exist
  if [ $debug -gt 1 ]; then echo "DEBUG: preReqs";fi
    for file in /bin/awk /bin/grep /bin/rpm /bin/sed /usr/bin/createrepo /usr/bin/wc /usr/bin/wget; do
    if [ ! -f ${file} ]; then 
      /bin/echo " ${file} not found. Cannot continue"; exit 1; 
    else 
      if [ $debug -gt 0 ]; then /bin/echo -n ".";fi; 
    fi
  done
  if [ $debug -gt 1 ]; then echo ;fi
}
preReqs
checkDirs() {
  #make sure the directories we expect to be in place are
  if [ $debug -gt 1 ]; then echo "DEBUG: checkDirs";fi
  for osmajor in 5 6; do 
    for arch in i386 x86_64; do 
      for version in 1 5 6; do 
        if [[ ${osmajor} -eq 6 && ${version} -eq 1 ]];then if [ $debug -gt 0 ]; then echo -n "." ;fi ;else
          for dir in  ${TOPDIR}/${osmajor}/${arch}/5.${version} ${TOPDIR}/${osmajor}/${arch}/5.${version}/Packages ${TOPDIR}/${osmajor}/${arch}/5.${version}/repodata; do
            if [ ! -d ${dir} ]; then 
              /bin/echo;/bin/echo " ${dir} doesn't exist. creating"; mkdir -p ${dir}; 
              if [ $? -ne 0 ]; then 
                echo "Couldn't create. exiting!"; exit 1; 
              fi 
            else
              if [ $debug -gt 0 ]; then /bin/echo -n ".";fi;
            fi
          done
        fi
      done
    done
  done
  if [ $debug -gt 1 ]; then echo ;fi
}
checkDirs
getArchive() {
  if [ $debug -gt 1 ]; then echo "DEBUG: getArchive ";fi
  if [ -z $1 ]; then 
    echo "getArchive did not get an architecture. cannot continue"; exit 1;
  elif [ -z $2 ]; then
    echo "getArchive did not get told whether to pull the RPMs for ${1}. Cannot continue"; exit 1;
  elif [ -z $3 ]; then
    echo "getArchive did not get told which major os version to pull the RPMs for ${1}. Cannot continue"; exit 1;
  elif [ -z $4 ]; then
    echo "getArchive did not get told if we are to download RPMs for ${2} ${1}. Cannot continue"; exit 1;
  elif [ -z $5 ]; then
    echo "getArchive did not get told what version of mysql to download RPMs ${2} ${1}. Cannot continue"; exit 1;
  elif [ -z $6 ]; then
    echo "getArchive did not get told if we are to download RPMs for ${2} ${1} MySQL ${5}. Cannot continue"; exit 1;
  else
    ARCH=$1
    ENABLE=$2
    MAJORENABLE=$4
    VERSIONENABLE=$6
    if [ $3 -eq 5 ]; then
      MAJORPATTERN='rhel5'
      MAJOR=5
    elif [ $3 -eq 6 ]; then
     MAJORPATTERN='el6'
     MAJOR=6
    else
      echo "got unexpected value of $3 for OSMajor. expecting 5 or 6. cannot continue"; exit 1
    fi
    if [ $5 -eq 51 ]; then
      NODOTVER=51
      DOTVER="5.1"
    elif [ $5 -eq 55 ]; then
      NODOTVER=55
      DOTVER="5.5"
    elif [ $5 -eq 56 ]; then
      NODOTVER=56
      DOTVER="5.6"
    else
      echo "got unexpected value of $5 for MySQL version. expecting 51 55 or 56. Cannot continue";exit 1
    fi
  fi

  if [ $MAJORENABLE == "true" ]; then
    if [ $ENABLE == "true" ]; then
      if [ $VERSIONENABLE == "true" ]; then
        if [ $debug -gt 2 ]; then echo "DEBUG: getArchive: ${MAJORPATTERN} ${ARCH} MySQL${DOTVER}  true";fi
        #now we should change into the package directory and get the packages
        cd ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages
        NUM=`/bin/grep ${ARCH} ${FILE} |/bin/grep ${MAJORPATTERN}|wc -l`
        NUMPRESENT=0
        if [ $debug -gt 0 ]; then echo; echo  "(Archive) MySQL ${DOTVER} ${MAJORPATTERN} ${ARCH}";fi
        for pkgfile in `/bin/grep ${ARCH} ${FILE} |/bin/grep ${MAJORPATTERN}|awk -Fmysql-${DOTVER}/ '{print $2}'`; do
          if [[ -f ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages/${pkgfile} && `/bin/rpm -K --nogpg ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages/${pkgfile}>/dev/null 2>&1; echo $?` -eq 0  ]]; then
            #file exists
            let "NUMPRESENT=NUMPRESENT+1"
            if [ ${NUMPRESENT} -lt ${NUM} ]; then
              if [ $debug -gt 0 ]; then echo -n ".";fi
            fi
          else
            #we have to get the file
            if [ $debug -gt 0 ]; then echo -n "${NUMPRESENT} / ${NUM}";fi
            /usr/bin/wget  http://downloads.mysql.com/archives/mysql-${DOTVER}/${pkgfile} -O ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages/${pkgfile}  >/dev/null 2>&1
            if [ $? -eq 0 ]; then if [ $debug -gt 0 ]; then echo -en '\r';fi ; else echo "Download of http://downloads.mysql.com/archives/mysql-${DOTVER}/${pkgfile} failed!"; exit 1;fi
            let "NUMPRESENT=NUMPRESENT+1"
          fi
        done
      else
        if [ $debug -gt 2 ]; then echo "DEBUG: getArchive: ${MAJORPATTERN} ${ARCH}  MySQL${DOTVER} false";fi
      fi
    else
      if [ $debug -gt 2 ]; then echo "DEBUG: getArchive: ${ARCH} false";fi
    fi
  else
    if [ $debug -gt 2 ]; then echo "DEBUG: getArchive: ${MAJORPATTERN} false";fi
  fi

  if [ $debug -gt 1 ]; then echo ;fi
}
getPkg() {
  if [ $debug -gt 1 ]; then echo "DEBUG: getPkg ";fi
  if [ -z $1 ]; then 
    echo "getPkg did not get an architecture. cannot continue"; exit 1;
  elif [ -z $2 ]; then
    echo "getPkg did not get told whether to pull the RPMs for ${1}. Cannot continue"; exit 1;
  elif [ -z $3 ]; then
    echo "getPkg did not get told which major os version to pull the RPMs for ${1}. Cannot continue"; exit 1;
  elif [ -z $4 ]; then
    echo "getPkg did not get told if we are to download RPMs for ${2} ${1}. Cannot continue"; exit 1;
  elif [ -z $5 ]; then
    echo "getPkg did not get told what version of mysql to download RPMs ${2} ${1}. Cannot continue"; exit 1;
  elif [ -z $6 ]; then
    echo "getPkg did not get told if we are to download RPMs for ${2} ${1} MySQL ${5}. Cannot continue"; exit 1;
  else
    ARCH=$1
    ENABLE=$2
    MAJORENABLE=$4
    VERSIONENABLE=$6
    if [ $3 -eq 5 ]; then
      MAJORPATTERN='rhel5'
      MAJOR=5
    elif [ $3 -eq 6 ]; then
     MAJORPATTERN='el6'
     MAJOR=6
    else
      echo "got unexpected value of $3 for OSMajor. expecting 5 or 6. cannot continue"; exit 1
    fi
    if [ $5 -eq 51 ]; then
      NODOTVER=51
      DOTVER="5.1"
    elif [ $5 -eq 55 ]; then
      NODOTVER=55
      DOTVER="5.5"
    elif [ $5 -eq 56 ]; then
      NODOTVER=56
      DOTVER="5.6"
    else
      echo "got unexpected value of $5 for MySQL version. expecting 51 55 or 56. Cannot continue";exit 1
    fi
  fi

  if [ $MAJORENABLE == "true" ]; then
    if [ $ENABLE == "true" ]; then
      if [ $VERSIONENABLE == "true" ]; then
        if [ $debug -gt 2 ]; then echo "DEBUG: getPkg: ${MAJORPATTERN} ${ARCH} MySQL${DOTVER}  true";fi
        #now we should change into the package directory and get the packages
        cd ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages
        NUM=`/bin/grep ${ARCH} ${TEMPFILE} |/bin/grep ${MAJORPATTERN}|wc -l`
        if [ $debug -gt 5 ]; then echo "Total number of ${ARCH} ${MAJORPATTERN} packages in ${TEMPFILE} file: ${NUM}";fi
        NUMPRESENT=0
        if [ $debug -gt 0 ]; then echo; echo  "MySQL ${DOTVER} ${MAJORPATTERN} ${ARCH}";fi
        for url in `/bin/grep ${ARCH} ${TEMPFILE} |/bin/grep ${MAJORPATTERN}`; do
          pkgfile=`echo ${url}|awk -F\/ '{print $6}'`
          if [[ -f ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages/${pkgfile} && `/bin/rpm -K --nogpg ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages/${pkgfile}>/dev/null 2>&1; echo $?` -eq 0  ]]; then
            #file exists
            let "NUMPRESENT=NUMPRESENT+1"
            if [ ${NUMPRESENT} -lt ${NUM} ]; then
              if [ $debug -gt 0 ]; then echo -n ".";fi
            fi
          else
            #we have to get the file
            if [ $debug -gt 0 ]; then echo -n "${NUMPRESENT} / ${NUM}";fi
            /usr/bin/wget  ${url} -O ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}/Packages/${pkgfile} >/dev/null 2>&1
            if [ $? -eq 0 ]; then if [ $debug -gt 0 ]; then echo -en '\r';fi ; else echo "Download of ${url} failed!"; exit 1;fi
            let "NUMPRESENT=NUMPRESENT+1"
          fi
        done
      else
        if [ $debug -gt 2 ]; then echo "DEBUG: getPkg: ${MAJORPATTERN} ${ARCH}  MySQL${DOTVER} false";fi
      fi
    else
      if [ $debug -gt 2 ]; then echo "DEBUG: getPkg: ${ARCH} false";fi
    fi
  else
    if [ $debug -gt 2 ]; then echo "DEBUG: getPkg: ${MAJORPATTERN} false";fi
  fi

  if [ $debug -gt 1 ]; then echo ;fi
}
updateRepo() {
  if [ $UPDATEREPO ]; then
    if [ $debug -gt 1 ]; then echo "DEBUG: updateRepo: $1 $2 $3 $4";fi
    if [ -z $1 ]; then echo "updateRepo: Did not get the OSMajor I should update the repo for. cannot continue";exit 1;
    elif [ -z $2 ]; then echo "updateRepo: Did not get the arch I should update the rhel $1 repo for. cannot continue";exit 1
    elif [ -z $3 ]; then echo "updateRepo: Did not get the mysql version I should update the rhel $1 $2 repo for. cannot continue";exit 1;
    elif [ -z $4 ]; then echo "updateRepo: Cannot determine if I should update the rhel $1 $2 repo for MySQL $3. cannot continue";exit 1;
    else
      MAJOR=$1
      ARCH=$2
      DOTVER=$3
      UPDATE=$4
    fi
    if [ $UPDATE ]; then
      if [ -d ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER} ]; then
        #the directory exists.
        if [ $debug -gt 1 ]; then 
          echo; /usr/bin/createrepo -s sha -v ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER}
        else
         if [ $debug -gt 0 ]; then echo; /usr/bin/createrepo -s sha ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER} ; echo -n ".";
         else /usr/bin/createrepo -s sha ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER} >/dev/null 2>&1;
         fi
        fi
      else
        echo "The directory ${TOPDIR}/${MAJOR}/${ARCH}/${DOTVER} doesn't exist cannot run createrepo for it. Update=$UPDATE ( $4 ) ";exit 1
      fi
    else
      if [ $debug -gt 1 ]; then echo "DEBUG: updateRepo: skipping RH${MAJOR} ${ARCH} MySQL ${DOTVER}";else echo -n ".";fi
    fi
  else 
    echo "DEBUG: updateRepo: UPDATEREPO = ${UPDATEREPO}. Not updating repos";
  fi
}
getArchTmp() {
  if [ $debug -gt 1 ]; then echo "DEBUG: getArchTmp: $1";fi
  if [ -z $1 ]; then 
    echo "getArchTmp did not get a MySQL Version. cannot continue"; exit 1;
  fi
    if [ $1 -eq 51 ]; then
      NODOTVER=51
      DOTVER="5.1"
      GET=$GET51
      TEMPFILE=/tmp/ARCHTEMPmysql51`date +%m%d%y-%H`
      FILE=/tmp/ARCHmysql51`date +%m%d%y-%H`
      export FILE
      export TEMPFILE
    elif [ $1 -eq 55 ]; then
      NODOTVER=55
      DOTVER="5.5"
      GET=$GET55
      TEMPFILE=/tmp/ARCHTEMPmysql55`date +%m%d%y-%H`
      FILE=/tmp/ARCHmysql55`date +%m%d%y-%H`
      export FILE
      export TEMPFILE
    elif [ $1 -eq 56 ]; then
      NODOTVER=56
      DOTVER="5.6"
      GET=$GET56
      TEMPFILE=/tmp/ARCHTEMPmysql56`date +%m%d%y-%H`
      FILE=/tmp/ARCHmysql56`date +%m%d%y-%H`
      export FILE
      export TEMPFILE
    else
      echo "got unexpected value of $5 for MySQL version. expecting 51 55 or 56. Cannot continue";exit 1
    fi
  if [ $debug -gt 2 ]; then 
    /usr/bin/wget http://downloads.mysql.com/archives.php?p=mysql-${DOTVER}\&o=rpm -O ${TEMPFILE}
  else
    /usr/bin/wget http://downloads.mysql.com/archives.php?p=mysql-${DOTVER}\&o=rpm -O ${TEMPFILE}>/dev/null 2>&1 
  fi
  if [ $? -eq 0 ]; then 
    if [ $debug -gt 0 ]; then echo -n .;fi; 
  else echo "Download of file failed. Fix!"; exit 1;
  fi
  sed -i -e 's/^.*\/archives/http:\/\/downloads.mysql.com\/archives/' -e 's/.rpm.*/.rpm/' ${TEMPFILE}
  if [ $? -eq 0 ]; then
    if [ $debug -gt 0 ]; then echo -n .;fi; 
  else echo "fixup of downloaded page failed. Fix!"; exit 1;
  fi
  sed -n -e '/downloads.mysql.com/{p;n}' ${TEMPFILE} > ${FILE} 
  if [ $? -eq 0 ]; then
    if [ $debug -gt 0 ]; then echo -n .;fi;
  else echo "fixup of ${TEMPFILE}  into ${FILE} failed. Fix!"; exit 1;
  fi
  getArchive "i386" $GETi386 5 $GET5 $NODOTVER $GET
  getArchive "x86_64" $GETx86_64 5 $GET5 $NODOTVER $GET
  if [ $NODOTVER -gt 52 ]; then 
    getArchive "i386" $GETi386 6 $GET6 $NODOTVER $GET
    getArchive "x86_64" $GETx86_64 6 $GET6 $NODOTVER $GET
  fi
  if [ $debug -gt 2 ]; then echo "Not cleaning up, as debug is enabled. please delete ${TEMPFILE} and ${FILE} manually"; else cleanUp;fi
} 
getTmp() {
  if [ $debug -gt 1 ]; then echo "DEBUG: getTmp: $1";fi
  if [ -z $1 ]; then 
    echo "getTmp did not get a MySQL Version. cannot continue"; exit 1;
  fi
  if [ -z $2 ]; then
    echo "getTmp did not get an OS major version. Cannot continue."; exit 1;
  fi
  #set mysql variables
  if [ $1 -eq 51 ]; then
    NODOTVER=51
    DOTVER="5.1"
    GET=$GET51
    TEMPFILE=/tmp/TEMPmysql51`date +%m%d%y-%H`
    FILE=/tmp/mysql51`date +%m%d%y-%H`
    export FILE
    export TEMPFILE
  elif [ $1 -eq 55 ]; then
    NODOTVER=55
    DOTVER="5.5"
    GET=$GET55
    TEMPFILE=/tmp/TEMPmysql55`date +%m%d%y-%H`
    FILE=/tmp/mysql55`date +%m%d%y-%H`
    export FILE
    export TEMPFILE
  elif [ $1 -eq 56 ]; then
    NODOTVER=56
    DOTVER="5.6"
    GET=$GET56
    TEMPFILE=/tmp/TEMPmysql56`date +%m%d%y-%H`
    FILE=/tmp/mysql56`date +%m%d%y-%H`
    export FILE
    export TEMPFILE
  else
    echo "got unexpected value of $5 for MySQL version. expecting 51 55 or 56. Cannot continue";exit 1
  fi
  #set OS Major variables
  if [ $2 -eq 5 ]; then
    OSVAR=7
    PKGMATCH="rhel5"
  elif [ $2 -eq 6 ]; then
    OSVAR=31
    PKGMATCH="el6"
  else
    echo "got unexpected value of $2 for OS Major version. Expecting 5 or 6. Cannot continue"; exit 1
  fi

  if [ $debug -gt 2 ]; then 
    echo "Running: /usr/bin/curl -F \"current_os=${OSVAR},version=${DOTVER}\" http://dev.mysql.com/downloads/mysql/#downloads -o ${TEMPFILE}"
    /usr/bin/curl -F "current_os=${OSVAR},version=${DOTVER}" http://dev.mysql.com/downloads/mysql/#downloads -o ${TEMPFILE}
  else
    /usr/bin/curl -s -F "current_os=${OSVAR},version=${DOTVER}" http://dev.mysql.com/downloads/mysql/#downloads -o ${TEMPFILE}
  fi
  if [ $? -eq 0 ]; then if [ $debug -gt 0 ]; then echo -n .;fi; else echo "Download of file failed. Fix!"; exit 1;fi
  awk -Fhref=\" '/mirror.php/ {print $2}' ${TEMPFILE} |awk -F\" '{print "http://dev.mysql.com"$1}' > ${FILE}
  if [ $? -eq 0 ]; then if [ $debug -gt 0 ]; then echo -n .;fi; else echo "fixup of downloaded page failed. Fix!"; exit 1;fi
  if [ $debug -gt 2 ]; then echo "getTmp: DEBUG: getting real URL for"; fi
  > ${TEMPFILE}
  for URL in `cat ${FILE}`; do
     if [ $debug -gt 2 ]; then echo ${URL};fi
     curl -s ${URL}|awk -Fhref=\"\/get '/cdn/ {print $2}'|awk -Frpm '{print "http://cdn.mysql.com"$1"rpm"}' >> ${TEMPFILE}
  done
  if [ $? -eq 0 ]; then if [ $debug -gt 0 ]; then echo -n .;fi ; else echo "fixup of ${TEMPFILE}  into ${FILE} failed. Fix!"; exit 1;fi
  if [ $2 -eq 5 ]; then
    getPkg "i386" $GETi386 5 $GET5 $NODOTVER $GET
    getPkg "x86_64" $GETx86_64 5 $GET5 $NODOTVER $GET
  elif [ $2 -eq 6 ]; then 
    getPkg "i386" $GETi386 6 $GET6 $NODOTVER $GET
    getPkg "x86_64" $GETx86_64 6 $GET6 $NODOTVER $GET
  fi
  if [ $debug -gt 1 ]; then echo "Not cleaning up, as debug is enabled. please delete ${TEMPFILE} and ${FILE} manually"; else cleanUp;fi
} 
cleanUp() {
  /bin/rm -f ${TEMPFILE} ${FILE}
  if [ $debug -gt 0 ]; then echo; echo "Done!";fi
}
getArchTmp 51
getArchTmp 55
getTmp 55 5
getTmp 55 6
getArchTmp 56
getTmp 56 5
getTmp 56 6
for UpdateVERSION in 5.1 5.5 5.6; do
  updateRepo 5 i386   ${UpdateVERSION} $GETi386
  updateRepo 5 x86_64 ${UpdateVERSION} $GETx86_64
done
for UpdateVERSION in 5.5 5.6; do
  updateRepo 6 i386   ${UpdateVERSION} $GETi386
  updateRepo 6 x86_64 ${UpdateVERSION} $GETx86_64
done