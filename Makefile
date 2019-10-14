PLAYBOOKS = $(shell find ./ -iname *.yml -printf '%P\n' | grep 'ansible_logic.yml')

.PHONY: all 
all: ansible-syntax-check

.PHONY: ansible-syntax-check
ansible-syntax-check:
	@echo "------------------"
	@echo "--> Check playbook syntax"
	@echo "------------------"
	rc_sum=0; \
	for playbook in $(PLAYBOOKS); do \
		sudo docker run --rm -ti --entrypoint=ansible-playbook litmuschaos/ansible-runner:ci \
		$${playbook} --syntax-check -i /etc/ansible/hosts -v; \
		rc_sum=$$((rc_sum+$$?)); \
	done; \
	exit $${rc_sum}
