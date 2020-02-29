FROM i386/ubuntu:bionic

# RUN echo 'Acquire::http::Proxy "http://10.0.0.10:3142";' > /etc/apt/apt.conf.d/00aptproxy

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV DISPLAY :1

ENV IQFEED_PRODUCT_ID IQLINK
ENV IQFEED_PRODUCT_VERSION 6.1.0.20
ENV IQFEED_LOGIN 123456
ENV IQFEED_PASSWORD 123456
ENV IQFEED_LOG_LEVEL 0xB222

# create a wine user
ENV HOME /home/wine
ENV WINEPREFIX $HOME/.wine
ENV WINEDEBUG -all
RUN useradd --user-group --create-home --home-dir $HOME --shell /bin/bash wine 

WORKDIR $HOME

# install wine and dependencies
RUN apt-get update && \
    apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends \
        software-properties-common apt-utils supervisor curl xvfb gpg-agent bbe netcat-openbsd && \
    # fix for missing wine dependencies
    curl https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/Release.key | apt-key add && \
    curl https://dl.winehq.org/wine-builds/winehq.key | apt-key add && \
    apt-add-repository 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/ ./' && \
    add-apt-repository 'deb http://dl.winehq.org/wine-builds/ubuntu/ bionic main' && \
    # install wine
    apt-get update && \
    apt-get purge *wine* && \
    apt-get install -yq --no-install-recommends \
        libfaudio0 libasound2-plugins wine-stable winehq-stable winbind winetricks

RUN su -pl wine -c 'winecfg && wineserver --wait' && \
    su -pl wine -c 'winetricks -q nocrashdialog && wineserver --wait' && \
    curl http://www.iqfeed.net/iqfeed_client_6_1_0_20.exe > $HOME/.wine/drive_c/iqfeed_install.exe && \
    su -pl wine -c "/usr/bin/xvfb-run -s -noreset -a /usr/bin/wine $HOME/.wine/drive_c/iqfeed_install.exe /S && wineserver --wait" && \
    su -pl wine -c "wine reg add HKEY_CURRENT_USER\\\Software\\\DTN\\\IQFeed\\\Startup /t REG_DWORD /v LogLevel /d $IQFEED_LOG_LEVEL /f && wineserver --wait"

# 'hack' to allow the client to listen on other interfaces
RUN bbe -e 's/127.0.0.1/000.0.0.0/g' "$HOME/.wine/drive_c/Program Files/DTN/IQFeed/iqconnect.exe" > "$HOME/.wine/drive_c/Program Files/DTN/IQFeed/iqconnect_patched.exe"

# cleanup
RUN apt-get autoremove -y --purge && \
    apt-get clean -y && \
    rm -rf /home/wine/.cache /var/lib/apt/lists/* $HOME/.wine/drive_c/iqfeed_install.exe

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
EXPOSE 9100
EXPOSE 5009
EXPOSE 9200
EXPOSE 9300
EXPOSE 9400
