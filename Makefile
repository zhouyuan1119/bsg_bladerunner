
include Makefile.common
DESIGN_NAME := manycore
BUCKET_NAME := bsgamibuild


.PHONY: all build-dcp upload-agfi build-ami clean help

.DEFAULT_GOAL := all
all: help
help:
	@echo "Usage:"
	@echo "make {build-ami|build-dcp|upload-agfi|clean} "
	@echo "		build-ami: Build an Amazon Machine Image (AMI) using "
	@echo "		           the AGFI and AFI in Makefile.deps "
	@echo "		build-dcp: Compile the FPGA design (locally) with the "
	@echo "		           hashes and repositories in Makefile.deps "
	@echo "		upload-agfi: Upload the compiled FPGA design into S3 "
	@echo "		           and create an Amazon FPGA Image (AFI) "
	@echo "		           and an Amazon Global FPGA Image ID (AGFI)"
	@echo "		clean: Remove all build files and repositories"


build-ami: checkout-repos
	$(BSG_F1_DIR)/scripts/amibuild/build.py bsg_bladerunner_release@$(RELEASE_BRANCH) $(AFI_ID)

build-dcp: checkout-repos
	make -C $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/ build

upload-agfi: build-dcp upload.json

upload.json: build-dcp
	$(BSG_F1_DIR)/scripts/afiupload/upload.py $(BUILD_PATH) $(DESIGN_NAME) \
	    $(FPGA_IMAGE_VERSION) $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/build/checkpoints/to_aws/cl_$(DESIGN_NAME).Developer_CL.tar \
	    $(BUCKET_NAME) "BSG AWS F1 Manycore AGFI" $(foreach repo,$(DEPENDENCIES),-r $(repo)@$(call hash,$(repo)))

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
	rm -rf upload.json
