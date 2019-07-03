FROM debian:buster

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="Sandro Jäckel <sandro.jaeckel@gmail.com>" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="Red-Discord Bot" \
  org.label-schema.description="A multifunction Discord bot" \
  org.label-schema.url="https://github.com/Cog-Creators/Red-DiscordBot/tree/V3/develop" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/SuperSandro2000/docker-images" \
  org.label-schema.vendor="SuperSandro2000" \
  org.label-schema.version=$VERSION \
  org.label-schema.schema-version="1.0"

WORKDIR /app

RUN apt-get update -qq \
  && apt-get install --no-install-recommends -qqy default-jre-headless git libffi-dev libssl-dev \
  python3-dev python3-levenshtein python3-pip python3-setuptools unzip wget zip \
  && rm -rf /var/lib/apt/lists/*

COPY ["files/config.json", "/root/.config/Red-DiscordBot/"]

RUN apt-get update -qq \
  && apt-get install --no-install-recommends -qqy build-essential \
  && pip3 install --process-dependency-links --no-cache-dir --progress-bar off Red-DiscordBot[voice] \
  && apt-get remove -qqy build-essential \
  && apt-get autoremove -qqy \
  && rm -rf /var/lib/apt/lists/*

CMD [ "redbot", "docker" ]
