#!/bin/bash
:"
   Copyright (C) 2011-2023 Francisco Vilmar Cardoso Ruviaro

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA."

PATH=/opt/xensource/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export PATH
#
DATASNAPSHOT=`date +%Y-%m-%d`
HOSTNAME=$(echo $HOSTNAME | tr [a-z] [A-Z])
#
# Configuracoes para o envio do log pelo Telegram
#TELEGRAM
ID=""
TOKEN=""
URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
#
LOG=/tmp/snapshot-${HOSTNAME}-${DATASNAPSHOT}.log
touch /tmp/uuids_vm_snaps.txt
LISTADEUUIDDASVM=/tmp/uuids_vm_snaps.txt
#
echo -e "###################################################################"
echo -e "###################################################################" > ${LOG}
#
echo -e "\e[1m Resumo das acoes realizadas em ${HOSTNAME} `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S` \e[m"
echo -e "Resumo das acoes realizadas em ${HOSTNAME} `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S`" >> ${LOG}
#
echo -e "###################################################################"
echo -e "###################################################################" >> ${LOG}
#
echo -e "\e[34;1m Gerando Lista de UUID das VM's que estao rodando no ${HOSTNAME} \e[m"
echo -e "Gerando Lista de UUID das VM's que estao rodando no ${HOSTNAME}" >> ${LOG}
xe vm-list power-state=running is-control-domain=false is-a-snapshot=false | grep uuid | cut -d":" -f2 > ${LISTADEUUIDDASVM}
#
	if [ $? -eq 0 ]
	then
		echo -e "\e[34;1m Listagem de UUID das VM's que estao rodando no ${HOSTNAME} concluida com sucesso \e[m"
		echo -e "Listagem de UUID das VM's que estao rodando no ${HOSTNAME} concluida com sucesso" >> ${LOG}
		echo -e "###################################################################"
		echo -e "###################################################################" >> ${LOG}
		cat ${LISTADEUUIDDASVM}
		cat ${LISTADEUUIDDASVM} >> ${LOG}
		echo -e "###################################################################"
		echo -e "###################################################################" >> ${LOG}
	else
		echo -e "Ocorreu um erro ao obter Listagem de UUID das VM's que estao rodando no ${HOSTNAME}"
		echo -e "Ocorreu um erro ao obter Listagem de UUID das VM's que estao rodando no ${HOSTNAME}" >> ${LOG}
		exit 1
	fi
#
echo -e "\e[34;1m Iniciando laco de repeticao que cria snapshot \e[m"
echo -e "Iniciando laco de repeticao que cria snapshot" >> ${LOG}
echo -e "###################################################################"
echo -e "###################################################################" >> ${LOG}
echo -e "\e[34;1m Extraindo o Nome das VM a partir da Listagem de UUID \e[m"
echo "Extraindo o Nome das VM a partir da Listagem de UUID" >> ${LOG}
echo -e "###################################################################"
echo -e "###################################################################" >> ${LOG}
while read VMUUID
do
	VMNAME=`xe vm-list uuid=${VMUUID} | grep name-label | cut -d":" -f2 | sed 's/^ *//g'`
	if [ $? -eq 0 ]
	then
		echo -e "\e[33;1m Extracao do Nome da VM a partir da Listagem de UUID ocorreu com sucesso \e[m"
		echo -e "Extracao do Nome da VM a partir da Listagem de UUID ocorreu com sucesso" >> ${LOG}
		echo -e "\e[34;1m VM=\e[m\e[31;1m${VMNAME}\e[m \e[34;1mUUID=\e[m\e[31;1m${VMUUID}\e[m \e[m"
		echo -e "VM=${VMNAME} UUID=${VMUUID}" >> ${LOG}
	else
		echo -e "\e[31;1m Ocorreu um erro ao tentar fazer a Extracao do Nome da VM a partir da Listagem de UUID \e[m"
		echo -e "Ocorreu um erro ao tentar fazer a Extracao do Nome da VM a partir da Listagem de UUID" >> ${LOG}
	fi
echo -e "\e[34;1m Criando Snapshot da VM=\e[m\e[31;1m${VMNAME}\e[m \e[34;1mUUID=\e[m\e[31;1m${VMUUID}\e[m"
echo -e "Criando Snapshot da VM=${VMNAME} UUID=${VMUUID}" >> ${LOG}
			SNAPUUID=`xe vm-snapshot uuid=${VMUUID} new-name-label="${VMNAME}-${DATASNAPSHOT}-SNAPSHOT"`
			if [ $? -eq 0 ]
			then
				echo -e "\e[34;1m Snapshot=\e[m\e[31;1m${SNAPUUID}\e[m \e[34;1mda VM=\e[m\e[31;1m${VMNAME}\e[m \e[34;1mUUID=\e[m\e[31;1m${VMUUID}\e[m \e[34;1mcriado com sucesso\e[m"
				echo -e "Snapshot=${SNAPUUID} da VM=${VMNAME} UUID=${VMUUID} criado com sucesso" >> ${LOG}
				ARRAY_LISTADESNAPUUID=(`xe snapshot-list params=uuid snapshot-of=$(xe vm-list uuid=${VMUUID} --minimal) --minimal |	sed 's/,/ /g'`)
				for ((x=1; x < ${#ARRAY_LISTADESNAPUUID[*]}; x++)) ; do
					if [[ -n ${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}} ]]
					then
					echo -e "\e[34;1m Removendo o UUID=\e[m\e[31;1m${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}}\e[m \e[34;1mvinculado a VM=\e[m\e[31;1m${VMNAME}\e[m \e[34;1mUUID=\e[m\e[31;1m${VMUUID}\e[m"
					echo -e "Removendo o UUID=${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}} vinculado a VM=${VMNAME} UUID=${VMUUID}" >> ${LOG}
							xe snapshot-uninstall uuid=${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}} force=true
							if [ $? -eq 0 ]
							then
							echo -e "\e[34;1m Remocao do UUID=\e[m\e[31;1m${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}}\e[m \e[34;1mvinculado a VM=\e[m\e[31;1m${VMNAME}\e[m \e[34;1mUUID=\e[m\e[31;1m${VMUUID}\e[m \e[34;1mexecutado com sucesso\e[m"
							echo -e "Remocao do UUID=${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}} vinculado a VM=${VMNAME} UUID=${VMUUID} executado com sucesso" >> ${LOG}
							echo -e "###################################################################"
							echo -e "###################################################################" >> ${LOG}
							else
							echo -e "Ocorreu um erro ao tentar Remover UUID=${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}} vinculado a VM=${VMNAME} UUID=${VMUUID}"
							echo -e "Ocorreu um erro ao tentar Remover UUID=${ARRAY_LISTADESNAPUUID[$x]/${SNAPUUID}} vinculado a VM=${VMNAME} UUID=${VMUUID}" >> ${LOG}
							fi
					fi
				done
			else
			echo -e "Ocorreu um erro ao tentar fazer snapshot=${SNAPUUID} da VM=${VMNAME} UUID=${VMUUID}"
			echo -e "Ocorreu um erro ao tentar fazer snapshot=${SNAPUUID} da VM=${VMNAME} UUID=${VMUUID}" >> ${LOG}
			fi
done < ${LISTADEUUIDDASVM}
#
echo -e "\e[1m TERMINO DAS ACOES EM ${HOSTNAME} `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S` \e[m"
echo -e "TERMINO DAS ACOES EM ${HOSTNAME} `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S`" >> ${LOG}
echo -e "###################################################################"
echo -e "###################################################################" >> ${LOG}
echo -e "\e[31;5m Enviando log pelo Telegram\e[m"
curl --silent -X POST --data-urlencode "chat_id=${ID}" --data-urlencode "text=$(tail ${LOG})" ${URL}
echo -e "Removendo arquivo ${LOG} e ${LISTADEUUIDDASVM}"
rm -rf ${LOG} ${LISTADEUUIDDASVM}
echo "Script Concluido"
exit 0
