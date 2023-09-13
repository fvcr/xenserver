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
DATABACKUP=`date +%Y-%m-%d`
HOSTNAME=$(echo $HOSTNAME | tr [a-z] [A-Z])
#
# Configuracoes para o envio do log pelo Telegram
#TELEGRAM
ID=""
TOKEN=""
URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
#
DIASARMAZENAMENTOBACKUP=3
# Montar Storage Remoto
FS="cifs"
DEVICE_0="//192.168.1.200"
REMOTE_DIR_0="/backup"
STORAGE_0="${DEVICE_0}${REMOTE_DIR_0} -o username=backup,password=password"
DEVICE_1="//192.168.1.201"
REMOTE_DIR_1="/backup"
STORAGE_1="${DEVICE_1}${REMOTE_DIR_1} -o username=backup,password=password" 
DIRPONTODEMONTAGEM=/media
LOG=/tmp/backup-${HOSTNAME}-${DATABACKUP}.log
touch /tmp/uuids.txt
LISTADEUUIDDASVM=/tmp/uuids.txt
# Diretorio onde serao salvos os backups
DIRETORIOBACKUP=${DIRPONTODEMONTAGEM}/${HOSTNAME}/${DATABACKUP}
#
echo -e "Resumo das acoes realizadas em ${HOSTNAME} `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S` \n"
echo -e "Resumo das acoes realizadas em ${HOSTNAME} `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S` \n" > $LOG
#
	if [ -d ${DIRPONTODEMONTAGEM} ]
	then
		echo "Diretorio ${DIRPONTODEMONTAGEM} para ponto de montagem ja existe"
		echo "Diretorio ${DIRPONTODEMONTAGEM} para ponto de montagem ja existe" >> $LOG
	else
		echo "Diretorio ${DIRPONTODEMONTAGEM} para ponto de montagem nao existe, criando agora"
		echo "Diretorio ${DIRPONTODEMONTAGEM} para ponto de montagem nao existe, criando agora" >> $LOG
		mkdir -p ${DIRPONTODEMONTAGEM}
	fi
#
umount -f ${DIRPONTODEMONTAGEM}
echo "Montando o Dispositivo $STORAGE_0 em $DIRPONTODEMONTAGEM"
echo "Montando o Dispositivo $STORAGE_0 em $DIRPONTODEMONTAGEM" >> $LOG
mount -t $FS $STORAGE_0 $DIRPONTODEMONTAGEM;
echo "Testando se o Dispositivo $STORAGE_0 encontra-se montado em $DIRPONTODEMONTAGEM"
echo "Testando se o Dispositivo $STORAGE_0 encontra-se montado em $DIRPONTODEMONTAGEM" >> $LOG
	if mountpoint -q $DIRPONTODEMONTAGEM 
	then
		echo "O dispositivo $STORAGE_0 foi montado no Diretorio $DIRPONTODEMONTAGEM com sucesso, o script sera iniciado"
		echo "O dispositivo $STORAGE_0 foi montado no Diretorio $DIRPONTODEMONTAGEM com sucesso, o script sera iniciado" >> $LOG
	else
		umount -f $DIRPONTODEMONTAGEM
		echo "Montando o Dispositivo $STORAGE_1 em $DIRPONTODEMONTAGEM"
		echo "Montando o Dispositivo $STORAGE_1 em $DIRPONTODEMONTAGEM" >> $LOG
		mount -t $FS $STORAGE_1 $DIRPONTODEMONTAGEM;
		echo "Testando se o Dispositivo $STORAGE_1 encontra-se montado em $DIRPONTODEMONTAGEM"
		echo "Testando se o Dispositivo $STORAGE_1 encontra-se montado em $DIRPONTODEMONTAGEM" >> $LOG
	        if mountpoint -q $DIRPONTODEMONTAGEM
        	then
                	echo "O dispositivo $STORAGE_1 foi montado no Diretorio $DIRPONTODEMONTAGEM com sucesso, o script sera iniciado"
                	echo "O dispositivo $STORAGE_1 foi montado no Diretorio $DIRPONTODEMONTAGEM com sucesso, o script sera iniciado" >> $LOG
		else
			exit 1
		fi
	fi
#
# Remove os backups antigos
echo -e "\nRemovendo backup antigo"
echo -e "\nRemovendo backup antigo" >> $LOG
ANTIGOS=$(find $DIRPONTODEMONTAGEM/$HOSTNAME/* -ctime +$DIASARMAZENAMENTOBACKUP)
	if [ -z ${ANTIGOS} ]
		then
			echo -e "Nenhum arquivo com mais de $DIASARMAZENAMENTOBACKUP dias, nada foi deletado. \n"
	                echo -e "Nenhum arquivo com mais de $DIASARMAZENAMENTOBACKUP dias, nada foi deletado. \n" >> $LOG
		else
			rm -rf $ANTIGOS
		        if [ $? -eq 0 ]
			        then
			                echo -e "Os arquivos \n\n $ANTIGOS \n\nforam removidos \n"
			                echo -e "Os arquivos \n\n $ANTIGOS \n\nforam removidos \n" >> $LOG
				else
					echo -e "Erro ao deletar \n"
		                        echo -e "Erro ao deletar \n" >> $LOG
			fi
	fi
#
echo "Criando Diretorio de Backup"
echo "Criando Diretorio de Backup" >> $LOG
mkdir -p $DIRETORIOBACKUP
	if [ -d $DIRETORIOBACKUP ]
	then
		echo "O Diretorio de Backup $DIRETORIOBACKUP Existe"
		echo "O Diretorio de Backup $DIRETORIOBACKUP Existe" >> $LOG
 	else
		echo "O Diretorio de Backup $DIRETORIOBACKUP nao existe, criando agora"
		echo "O Diretorio de Backup $DIRETORIOBACKUP nao existe, criando agora" >> $LOG
		mkdir -p $DIRETORIOBACKUP
	fi
#
echo -e "\nGerando Lista de UUID das VM's que estao rodando no $HOSTNAME"
echo -e "\nGerando Lista de UUID das VM's que estao rodando no $HOSTNAME" >> $LOG
xe vm-list power-state=running is-control-domain=false is-a-snapshot=false | grep uuid | cut -d":" -f2 > $LISTADEUUIDDASVM
#
#TIRAR ESPACOS
sed -i 's/^ *//g' $LISTADEUUIDDASVM
##COLOCAR ABAIXO O UUID DA VM QUE NAO DESEJA FAZER O BACKUP, ISSO VAI SUBSTITUIR O UUID POR UMA LINHA EM BRANCO##
#sed -i 's/679a5123-8e87-6753-0989-1cd944ff37b9//' $LISTADEUUIDDASVM
#TIRAR ESPACOS DO ARQUIVO $LISTADEUUIDDASVM
sed -i 's/^ *//g' $LISTADEUUIDDASVM
#ELIMINAR LINHA EM BRANCO
sed -i '/^$/d' $LISTADEUUIDDASVM
#
	if [ $? -eq 0 ]
	then
		echo -e "Listagem de UUID das VM's que estao rodando no $HOSTNAME concluida com sucesso \n"
		echo -e "Listagem de UUID das VM's que estao rodando no $HOSTNAME concluida com sucesso \n" >> $LOG
		cat $LISTADEUUIDDASVM
		cat $LISTADEUUIDDASVM >> $LOG
	else
		echo -e "Ocorreu um erro ao obter Listagem de UUID das VM's que estao rodando no $HOSTNAME \n"
		echo -e "Ocorreu um erro ao obter Listagem de UUID das VM's que estao rodando no $HOSTNAME \n" >> $LOG
		cat $LISTADEUUIDDASVM
		cat $LISTADEUUIDDASVM >> $LOG
	fi
#
##############################################################################################
xe-backup-metadata -u $(xe pool-list params=default-SR --minimal)
##############################################################################################
echo -e "\nBackup pool-dump-database de $HOSTNAME \n"
echo -e "\nBackup pool-dump-database de $HOSTNAME \n" >> $LOG
xe pool-dump-database file-name="$DIRETORIOBACKUP/$HOSTNAME-pool-dump-database-$DATABACKUP.bk"
##############################################################################################
#xe pool-restore-database file-name=<backup> dry-run=true
##############################################################################################
echo -e "Backup host-backup de $HOSTNAME \n"
echo -e "Backup host-backup de $HOSTNAME \n" >> $LOG
xe host-backup host=$HOSTNAME file-name="$DIRETORIOBACKUP/$HOSTNAME-host-backup-$HOSTNAME-$DATABACKUP.bk"
##############################################################################################
#xe host-restore file-name=filename
##############################################################################################
echo -e "###################################################################\n\n"
echo -e "###################################################################\n\n" >> $LOG
echo -e "Iniciando laco de repeticao que cria snapshot, converte o snapshot de template para VM, faz a exportacao dessa VM e remove o snapshot \n"
echo -e "Iniciando laco de repeticao que cria snapshot, converte o snapshot de template para VM, faz a exportacao dessa VM e remove o snapshot \n" >> $LOG
while read VMUUID
do
echo -e "Horario: `date +%H:%M:%S` \n"
echo -e "Horario: `date +%H:%M:%S` \n" >> $LOG
echo "Extraindo o Nome das VM a partir da Listagem de UUID"
echo "Extraindo o Nome das VM a partir da Listagem de UUID" >> $LOG
	VMNAME=`xe vm-list uuid=$VMUUID| grep name-label | cut -d":" -f2 | sed 's/^ *//g'`
	if [ $? -eq 0 ]
	then
		echo -e "Extracao do Nome da VM a partir da Listagem de UUID ocorreu com sucesso"
		echo -e "VM=$VMNAME UUID=$VMUUID \n"
		echo -e "Extracao do Nome da VM a partir da Listagem de UUID ocorreu com sucesso" >> $LOG
		echo -e "VM=$VMNAME UUID=$VMUUID \n" >> $LOG
	else
		echo -e "Ocorreu um erro ao tentar fazer a Extracao do Nome da VM a partir da Listagem de UUID \n"
		echo -e "Ocorreu um erro ao tentar fazer a Extracao do Nome da VM a partir da Listagem de UUID \n" >> $LOG
	fi
echo "Criando Snapshot da VM=$VMNAME UUID=$VMUUID"
echo "Criando Snapshot da VM=$VMNAME UUID=$VMUUID" >> $LOG
			SNAPUUID=`xe vm-snapshot uuid=$VMUUID new-name-label="$VMNAME-$VMUUID-$DATABACKUP"`
			if [ $? -eq 0 ]
			then
				echo -e "Snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID criado com sucesso \n"
				echo -e "Snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID criado com sucesso \n" >> $LOG
			else
				echo -e "Ocorreu um erro ao tentar fazer snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID \n"
				echo -e "Ocorreu um erro ao tentar fazer snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID \n" >> $LOG
			fi
echo "Convertendo o SNAPSHOT=$SNAPUUID da VM=$VMNAME UUID=$VMUUID"
echo "Convertendo o SNAPSHOT=$SNAPUUID da VM=$VMNAME UUID=$VMUUID" >> $LOG
				xe template-param-set is-a-template=false ha-always-run=false uuid=$SNAPUUID
				if [ $? -eq 0 ]
				then
					echo -e "Conversao do Snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID de Template para VM executado com sucesso \n"
					echo -e "Conversao do Snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID de Template para VM executado com sucesso \n" >> $LOG
				else
					echo -e "Ocorreu um erro ao tentar converter snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID de Template para VM \n"
					echo -e "Ocorreu um erro ao tentar converter snapshot=$SNAPUUID da VM=$VMNAME UUID=$VMUUID de Template para VM \n" >> $LOG
				fi
echo "Exportando a VM UUID=$SNAPUUID Backup da VM=$VMNAME UUID=$VMUUID"
echo "Exportando a VM UUID=$SNAPUUID Backup da VM=$VMNAME UUID=$VMUUID" >> $LOG
				        xe vm-export filename="$DIRETORIOBACKUP/metadados-$VMNAME-$DATABACKUP" uuid=$VMUUID metadata=true
					xe vm-export vm=$SNAPUUID filename="$DIRETORIOBACKUP/$VMNAME-$DATABACKUP.xva" compress=true
					if [ $? -eq 0 ]
					then
						echo -e "Exportacao da VM=$SNAPUUID Backup da VM=$VMNAME UUID=$VMUUID executado com sucesso \n"
						echo -e "Exportacao da VM=$SNAPUUID Backup da VM=$VMNAME UUID=$VMUUID executado com sucesso \n" >> $LOG
					else
						echo -e "Ocorreu um erro ao tentar Exportar a VM=$SNAPUUID Backup da VM=$VMNAME UUID=$VMUUID \n"
						echo -e "Ocorreu um erro ao tentar Exportar a VM=$SNAPUUID Backup da VM=$VMNAME UUID=$VMUUID \n" >> $LOG
					fi
echo "Removendo o UUID=$SNAPUUID vinculado a VM=$VMNAME UUID=$VMUUID"
echo "Removendo o UUID=$SNAPUUID vinculado a VM=$VMNAME UUID=$VMUUID" >> $LOG
						xe vm-uninstall uuid=$SNAPUUID force=true
						if [ $? -eq 0 ]
						then
							echo -e "Remocao do UUID=$SNAPUUID vinculado a VM=$VMNAME UUID=$VMUUID executado com sucesso \n"
							echo -e "Remocao do UUID=$SNAPUUID vinculado a VM=$VMNAME UUID=$VMUUID executado com sucesso \n" >> $LOG
						else
							echo -e "Ocorreu um erro ao tentar Remover UUID=$SNAPUUID vinculado a VM=$VMNAME UUID=$VMUUID \n"
							echo -e "Ocorreu um erro ao tentar Remover UUID=$SNAPUUID vinculado a VM=$VMNAME UUID=$VMUUID \n" >> $LOG
						fi
echo -e "###################################################################\n\n"
echo -e "###################################################################\n\n" >> $LOG
done < $LISTADEUUIDDASVM
#
echo -e "TERMINO DAS ACOES EM $HOSTNAME `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S`"
echo -e "TERMINO DAS ACOES EM $HOSTNAME `date +%A` dia `date +%d` de `date +%B` de `date +%Y` as `date +%H:%M:%S`" >> $LOG
echo "Enviando log pelo Telegram"
curl --silent -X POST --data-urlencode "chat_id=${ID}" --data-urlencode "text=$(tail ${LOG})" ${URL}
echo "Desmontando $DIRPONTODEMONTAGEM"
umount $DIRPONTODEMONTAGEM
echo "Removendo arquivo ${LOG} e ${LISTADEUUIDDASVM:5}"
rm -rf ${LOG} ${LISTADEUUIDDASVM}
echo "Script Concluido"
exit 0
