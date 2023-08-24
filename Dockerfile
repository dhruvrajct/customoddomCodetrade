FROM ubuntu:22.04
LABEL key="CodeTrade India Pvt Ltd <info@codetrade.io>"  

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Set non-interactive mode and configure time zone
ENV DEBIAN_FRONTEND=noninteractive


# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        git \
        python3-dev \
        gcc \
        libffi-dev \
        postgresql-client-14
    
#RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb && \
    #apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    #rm -rf /var/lib/apt/lists/* wkhtmltox.deb
# Install rtlcss (on Debian buster)
#RUN apt-get update && apt-get install -y  libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev
RUN npm install -g rtlcss
RUN apt-get update && apt install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt install -y python3.7 python3.7-venv

RUN apt install -y python3.7-dev python3.8-dev \
        build-essential libsass-dev libjpeg-dev \
        libjpeg8-dev libldap-dev libldap2-dev \
        libpq-dev libsasl2-dev libxslt1-dev zlib1g-dev nano

# Add user odoo to System
RUN useradd -m -d /opt/odoo -U -r -s /bin/bash odoo
USER odoo
RUN mkdir /opt/odoo/odoo_ce_13

# Install Odoo
RUN git clone https://github.com/odoo/odoo.git --branch 13.0 --depth 1 /opt/odoo/odoo_ce_13
COPY ./requirements.txt /opt/odoo/odoo_ce_13/requirements.txt
RUN python3.7 -m pip install setuptools==57.0.0
RUN python3.7 -m pip install -r /opt/odoo/odoo_ce_13/requirements.txt

# Copy entrypoint script and Odoo configuration file
USER root
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod +x /usr/local/bin/wait-for-psql.py
USER odoo
# Set default user when running the container
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]