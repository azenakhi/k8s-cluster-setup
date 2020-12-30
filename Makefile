KUBE_VERSION = 1.19.3
DNS_DOMAIN := iaas.caphitech.com
DNSMASQ_PATH := /usr/local/etc/dnsmasq.d/multipass
KNOWN_HOSTS := ~/.ssh/known_hosts

MASTERS = master-1
WORKERS = worker-1 worker-2
ALL = $(MASTERS) $(WORKERS)

vm: $(addprefix vm-,$(ALL))

dns: $(addprefix dns-,$(ALL))

fingerprints: $(addprefix fingerprints-,$(ALL))

prerequisite: $(addprefix prerequisite-,$(ALL))

join: $(addprefix join-,$(WORKERS))

clean: $(addprefix clean-,$(ALL))

vm-%:
	@NODE=$* DNS_DOMAIN=$(DNS_DOMAIN) envsubst > /tmp/cloud-init-$*.yaml < cloud-init.yaml
	@multipass launch --name $* --cpus 2 --mem 4G --disk 20G --cloud-init /tmp/cloud-init-$*.yaml
	@rm -rf /tmp/cloud-init-$*.yaml

dns-%: 
	$(eval NODE_IP := $(shell multipass info $* --format json | jq '.info["$*"].ipv4[0]'))
	@echo address=/$*/$(NODE_IP) > $(DNSMASQ_PATH)_$*
	@echo address=/$*.$(DNS_DOMAIN)/$(NODE_IP) >> $(DNSMASQ_PATH)_$*
	@sudo brew services restart dnsmasq 2>/dev/null

fingerprints-%:
	$(eval NODE_IP := $(shell multipass info $* --format json | jq '.info["$*"].ipv4[0]'))
	ssh-keyscan -H $* >> $(KNOWN_HOSTS)
	ssh-keyscan -H $*.$(DNS_DOMAIN) >> $(KNOWN_HOSTS)
	ssh-keyscan -H $(NODE_IP) >> $(KNOWN_HOSTS)

prerequisite-%:
	@scp -r scripts root@$*:/root/
	@ssh root@$* "chmod +x /root/scripts/*"
	@ssh root@$* "/root/scripts/bash-completion.sh"
	@ssh root@$* "KUBE_VERSION=$(KUBE_VERSION) /root/scripts/prerequisite.sh"

init:
	$(eval MASTER_NAME := $(shell echo "master-1"))
	@ssh root@$(MASTER_NAME) "/root/scripts/init.sh"
	@ssh root@$(MASTER_NAME) "/root/scripts/network.sh"

join-%:
	$(eval MASTER_NAME := $(shell echo "master-1"))
	$(eval MASTER_IP := $(shell multipass info $(MASTER_NAME) --format json | jq '.info["$(MASTER_NAME)"].ipv4[0]'))
	$(eval TOKEN := $(shell ssh root@$(MASTER_NAME) 'kubeadm token create 2>/dev/null'))
	$(eval HASH := $(shell ssh root@$(MASTER_NAME) "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"))
	@ssh root@$* "kubeadm join --token $(TOKEN) --discovery-token-ca-cert-hash sha256:$(HASH) $(MASTER_IP):6443"

clean-%:
	# delete VMs
	@multipass stop --all
	@multipass delete --all
	@multipass purge
	# delete fingerprints
	$(eval NODE_IP := $(shell multipass info $* --format json | jq '.info["$*"].ipv4[0]'))
	@ssh-keygen -R $*
	@ssh-keygen -R $*.$(DNS_DOMAIN)
	@ssh-keygen -R $(NODE_IP).$(DNS_DOMAIN)
	#delete DNS
	@rm -rf $(DNSMASQ_PATH)_$*
	@sudo brew services restart dnsmasq 2>/dev/null
