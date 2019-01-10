for((i=17;i<=24;i++));  
do   
	ssh-copy-id -i /root/.ssh/id_rsa.pub 172.16.10.$i
done  
