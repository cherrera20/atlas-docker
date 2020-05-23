FROM maven:3.6-jdk-8 as builder

ARG VERSION=2.0.0

ENV DIST_MIRROR     https://archive.apache.org/dist/atlas
ENV ATLAS_BUILD     /opt/atlas-build
ENV ATLAS_HOME      /opt/atlas

RUN mkdir -p ${ATLAS_BUILD} ${ATLAS_HOME} && \
    wget -qO- ${DIST_MIRROR}/${VERSION}/apache-atlas-${VERSION}-sources.tar.gz | tar xvz -C ${ATLAS_BUILD} --strip-components=1 && \
    cd ${ATLAS_BUILD} && \
    sed -i "s#http://repo1.maven.org/maven2#https://repo1.maven.org/maven2#g" pom.xml && \
    mvn -DskipTests=true package -Pdist && \
    tar zxf ${ATLAS_BUILD}/distro/target/apache-atlas-${VERSION}-server.tar.gz --strip-components 1 -C ${ATLAS_HOME}

FROM debian:stretch

ENV ATLAS_HOME      /opt/atlas

COPY --from=builder ${ATLAS_HOME} ${ATLAS_HOME}

RUN apt-get update && \
    apt-get install -y python openjdk-8-jdk procps lsof && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -ms /bin/bash -d ${ATLAS_HOME} atlas && \
    chown -R atlas:atlas ${ATLAS_HOME}

COPY atlas /usr/local/bin/atlas
WORKDIR ${ATLAS_HOME}

USER atlas:atlas
EXPOSE 21000

CMD ["atlas"]