-include makefile.pass

# {{{ -- meta

DOCKERSRC        := $(OPSYS)_base

HOSTARCH         := x86_64
ARCH             := $(shell uname -m | sed "s_armv7l_armhf_") 

SHCOMMAND        := /bin/bash

REGISTRY	 := localhost:5000
IMAGETAG         := $(REGISTRY)/$(OPSYS)_$(SVCNAME)_$(DISTRIB):$(ARCH)

CNTNAME          := $(SVCNAME) # name for container name : $(OPSYS)_name, hostname : name

PUID             := $(shell id -u)
PGID             := $(shell id -g) 

# -- }}}

# {{{ -- docker build and run flags

BUILDFLAGS := --rm --force-rm --compress -f $(CURDIR)/dockerfile/Dockerfile.$(OPSYS)_$(SVCNAME).$(ARCH).$(DISTRIB) -t $(IMAGETAG) \
	--build-arg ARCH=$(ARCH) \
	--build-arg DOCKERSRC=$(DOCKERSRC) \
        --build-arg DISTRIB=$(DISTRIB) \
        --build-arg REGISTRY=$(REGISTRY) \
	--build-arg PUID=$(PUID) \
	--build-arg PGID=$(PGID) \
	--label org.label-schema.build-date=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
	--label org.label-schema.name=$(OPSYS)_$(SVCNAME) \
	--label org.label-schema.schema-version="1.0" \
        --build-arg http_proxy=http://192.168.2.28:3142

-include $(CURDIR)/include/makefile.$(OPSYS)_$(SVCNAME).$(ARCH).$(DISTRIB)

NAMEFLAGS  := --name $(OPSYS)_$(CNTNAME) --hostname $(CNTNAME)
RUNFLAGS   := -e PGID=$(PGID) -e PUID=$(PUID)

# -- }}}


# {{{ -- docker run args

CONTARGS    := #

# -- }}}


# {{{ -- docker targets

all : build start

build : 
	if [ "$(DISTRIB)" = "alpine" ]; then make fetch; fi
	echo "Building $(DISTRIB) for $(ARCH) from $(HOSTARCH)";
	if [ "$(ARCH)" != "$(HOSTARCH)" ]; then make regbinfmt fetchqemu ; fi;
	docker build $(BUILDFLAGS) $(CACHEFLAGS) $(PROXYFLAGS) .

clean :
	docker images | awk '(NR>1) && ($$2!~/none/) {print $$1":"$$2}' | grep "$(OPSYS)_$(SVCNAME)" | xargs -n1 docker rmi

rm : stop
	docker rm -f $(OPSYS)_$(CNTNAME)

start :
	docker run -d $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) $(CONTARGS)

rshell :
	docker exec -u root -it $(OPSYS)_$(CNTNAME) $(SHCOMMAND)

shell :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) $(SHCOMMAND)

stop :
	docker stop -t 2 $(OPSYS)_$(CNTNAME)

status :
	@docker container inspect $(OPSYS)_$(CNTNAME) | jq -r '.[] .State.Status'

# -- }}}

# {{{ -- other targets

pull :
	docker pull $(IMAGETAG)

push :
	docker push $(IMAGETAG); \
	if [ "$(ARCH)" = "$(HOSTARCH)" ]; \
		then \
		LATESTTAG=$$(echo $(IMAGETAG) | sed 's/:$(ARCH)/:latest/'); \
		docker tag $(IMAGETAG) $${LATESTTAG}; \
		docker push $${LATESTTAG}; \
	fi; 

test :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) sh -ec 'echo "do what you want here"'

regbinfmt :
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

ALPINE_VERSION   := 3.8.0

fetch:
	mkdir -p data && cd data \
	&& curl \
		-o ./rootfs.tar.gz -SL https://nl.alpinelinux.org/alpine/latest-stable/releases/$(ARCH)/alpine-minirootfs-$(ALPINE_VERSION)-$(ARCH).tar.gz \
		&& gunzip -f ./rootfs.tar.gz;

fetchqemu :
	mkdir -p data \
	&& QEMUARCH="$$(echo $(ARCH) | sed 's_armhf_arm_')" \
	&& QEMUVERS="$$(curl -SL https://api.github.com/repos/multiarch/qemu-user-static/releases/latest | awk '/tag_name/{print $$4;exit}' FS='[""]')" \
	&& echo "Using qemu-user-static version: "$${QEMUVERS} \
	&& curl \
		-o ./data/$(HOSTARCH)_qemu-$${QEMUARCH}-static.tar.gz -SL https://github.com/multiarch/qemu-user-static/releases/download/$${QEMUVERS}/$(HOSTARCH)_qemu-$${QEMUARCH}-static.tar.gz \
		&& tar xv -C data/ -f ./data/$(HOSTARCH)_qemu-$${QEMUARCH}-static.tar.gz;

# -- }}}
