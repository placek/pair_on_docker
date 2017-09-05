# This example installs rvm.

FROM reg01.binarapps.com/placek/pair:latest

RUN \
  apk --update --no-cache add bash && \
  apk --update --no-cache --virtual build_dpk add alpine-sdk gcc gnupg ruby procps \
    musl-dev make linux-headers zlib zlib-dev openssl openssl-dev libssl1.0 && \
  su - pair && \
  bash && \
  curl -sSL https://github.com/rvm/rvm/tarball/stable -o rvm-stable.tar.gz && \
  echo 'export rvm_prefix=\"/home/pair\"' > /home/pair/.rvmrc && \
  echo 'export rvm_path=\"/home/pair/.rvm\"' >> /home/pair/.rvmrc && \
  mkdir rvm && cd rvm && \
  tar --strip-components=1 -xzf ../rvm-stable.tar.gz && \
  ./install --auto-dotfiles --autolibs=0


