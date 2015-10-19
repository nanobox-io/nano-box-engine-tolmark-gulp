FROM nanobox/build

# Remove existing engines, we don't want to test those
RUN rm -rf /opt/engines/*

# Create folders for this engine
RUN mkdir -p /opt/engines/tolmark-gulp/bin && \
    mkdir -p /opt/engines/tolmark-gulp/templates && \
    mkdir -p /opt/tests/sample-tolmark-gulp

# Add in this engine's files
ADD bin/. /opt/engines/tolmark-gulp/bin
ADD templates/. /opt/engines/tolmark-gulp/templates
ADD tests/sample-tolmark-gulp/src/. /opt/tests/sample-tolmark-gulp