FROM i386/ubuntu:bionic

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
ENV IQFEED_SHUTDOWN_DELAY 300

ENV WINEPREFIX /root/.wine
ENV WINEDEBUG -all

WORKDIR /root

# install wine and dependencies
RUN apt-get update -qq && \
    apt-get upgrade -yqq && \
    apt-get install -yqq --no-install-recommends \
        software-properties-common apt-utils supervisor curl xvfb gpg-agent bbe netcat-openbsd && \
    # fix for missing wine dependencies
    curl https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/Release.key | apt-key add && \
    curl https://dl.winehq.org/wine-builds/winehq.key | apt-key add && \
    apt-add-repository 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/ ./' && \
    add-apt-repository 'deb http://dl.winehq.org/wine-builds/ubuntu/ bionic main' && \
    # install wine
    apt-get update -qq && \
    apt-get install -yqq --no-install-recommends \
        libfaudio0 libasound2-plugins wine-stable winehq-stable winbind winetricks

# installing iqfeed client
RUN winecfg && \
    winetricks -q nocrashdialog && \
    curl http://www.iqfeed.net/iqfeed_client_6_1_0_20.exe > /root/.wine/drive_c/iqfeed_install.exe && \
    /usr/bin/xvfb-run -s -noreset -a /usr/bin/wine /root/.wine/drive_c/iqfeed_install.exe /S && \
    wine reg add HKEY_CURRENT_USER\\\Software\\\DTN\\\IQFeed\\\Startup /t REG_DWORD /v LogLevel /d $IQFEED_LOG_LEVEL /f && \
    wine reg add HKEY_CURRENT_USER\\\Software\\\DTN\\\IQFeed\\\Startup /T REG_SZ /v SubmitAnonymousStats /d 0 /f && \
    wine reg add HKEY_CURRENT_USER\\\Software\\\DTN\\\IQFeed\\\Startup /t REG_SZ /v ShutdownDelayLastClient /d $IQFEED_SHUTDOWN_DELAY /f && \
    wine reg add HKEY_CURRENT_USER\\\Software\\\DTN\\\IQFeed\\\Startup /t REG_SZ /v ShutdownDelayStartup /d $IQFEED_SHUTDOWN_DELAY /f


# 'hack' to allow the client to listen on other interfaces
RUN bbe -e "s/127.0.0.1/000.0.0.0/g" "/root/.wine/drive_c/Program Files/DTN/IQFeed/iqconnect.exe" > "/root/.wine/drive_c/Program Files/DTN/IQFeed/iqconnect_patched.exe"

# cleanup
RUN apt-get autoremove -y --purge && \
    apt-get clean -y && \
    rm -rf /home/wine/.cache /var/lib/apt/lists/* /root/.wine/drive_c/iqfeed_install.exe

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

EXPOSE 9100
EXPOSE 5009
EXPOSE 9200
EXPOSE 9300
EXPOSE 9400
