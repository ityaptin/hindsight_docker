FROM debian:latest
MAINTAINER it

# NOTE(elemoine) hindsight and lua_sandbox are built from sources (specific
# commits). In the future we may want to create and host Debian packages.
#
#
RUN cd /tmp \
    && apt-get install --no-install-recommends -y python-dev \
    && git clone https://github.com/edenhill/librdkafka.git \
    && cd librdkafka \
    && ./configure \
    && make \
    && make install \
    && cd /tmp \
    && git clone https://github.com/mozilla-services/lua_sandbox.git \
    && cd lua_sandbox \
    #  https://github.com/mozilla-services/lua_sandbox/commit/f1ee9eb19f4d237b78b585a8b1c6d056e3b3c9fb
    && git checkout f1ee9eb19f4d237b78b585a8b1c6d056e3b3c9fb \
    && mkdir release \
    && cd release \
    && cmake -DCMAKE_BUILD_TYPE=release .. \
    && make \
    && make install \
    && apt-get install --no-install-recommends -y curl \
    && cd /tmp \
    && git clone https://github.com/trink/hindsight \
    && cd hindsight \
    # https://github.com/trink/hindsight/commit/056321863d4e03f843bbac48ace3ed5e88e4b8fc
    && git checkout 056321863d4e03f843bbac48ace3ed5e88e4b8fc \
    && mkdir release \
    && cd release \
    && cmake -DCMAKE_BUILD_TYPE=release .. \
    && make \
    && make install \
    && mkdir -p \
        /etc/hindsight \
        /var/lib/hindsight/output \
        /var/lib/hindsight/load/analysis \
        /var/lib/hindsight/load/input \
        /var/lib/hindsight/load/output \
        /var/lib/hindsight/run/analysis \
        /var/lib/hindsight/run/input \
        /var/lib/hindsight/run/output \
    && cp /tmp/lua_sandbox/sandboxes/heka/input/heka_tcp.lua /var/lib/hindsight/run/input/ \
    && cp /tmp/lua_sandbox/sandboxes/heka/input/syslog_udp.lua /var/lib/hindsight/run/input/ \
    && cp /tmp/hindsight/sandboxes/input/prune_input.lua /var/lib/hindsight/run/input/ \
    && cp /tmp/lua_sandbox/sandboxes/heka/input/heka_kafka.lua /var/lib/hindsight/run/input/ \
    && rm -rf /tmp/lua_sandbox /tmp/hindsight /tmp/librdkafka \ 
    && apt-get purge -y --auto-remove \
         ca-certificates git gcc g++ make cmake patch python-dev\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

VOLUME /usr/share/heka/lua_modules:/var/lib/heka_modules
VOLUME /usr/share/lma_collector/modules:/var/lib/lma_modules


ADD run/input/ceilometer_kafka.cfg run/input/ceilometer_kafka.lua /var/lib/hindsight/run/input/
ADD run/output/influxdb_ceilometer.cfg run/output/influxdb_tcp.lua /var/lib/hindsight/run/output/
ADD run/output/debug.cfg run/output/error.cfg run/output/debug.lua /var/lib/hindsight/run/output/
ADD run/analysis/influxdb_accumulator.cfg run/analysis/influxdb_accumulator.lua /var/lib/hindsight/run/analysis/


RUN useradd --user-group hindsight \
    && chown -R hindsight: /var/lib/hindsight

EXPOSE 5565

USER hindsight