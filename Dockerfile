# das ist ein abgespecktes build file vom apimanager gunicorn container
FROM registry.access.redhat.com/ubi9/python-39 AS builder
USER 0
RUN dnf update -y
# distro install bevorzugt
RUN dnf  install python3-psycopg2 -y
# . ist root dir apimanager
ADD . /app
# das hier zieht die settings aus umgebungsvariablen
RUN  cp /app/.github/local_settings_container.py /app/apimanager/apimanager/local_settings.py
# standard requirement install
RUN pip install -r /app/requirements.txt
RUN chown  501 /
RUN chown -R 501 /app
# group 0 damit openshift unter einer "zufaelligen" user id fahren kann.
# dieser user hat nur im container namespace group 0.
RUN chgrp -R 0 /app && chmod -R g+rwX /app
# nur zur sicherheit, falls der container doch mit der angebebenen uid ausgefuehrt wird
USER 501
WORKDIR /app
# wir brauchen hier nur die statischen files?
RUN python ./apimanager/manage.py collectstatic --noinput

# das hier ist jetzt der eigentliche nginx container
FROM registry.access.redhat.com/ubi9/nginx-120

USER 0
# nginx configuration.
#ADD .github/nginx.conf /opt/app-root/etc/nginx.default.d/default.conf
ADD .github/apimanager.conf "${NGINX_DEFAULT_CONF_PATH}"
# statische dateien aus dem builder image oben ins default(?) www verzeichnis kopieren
COPY --from=builder /app/apimanager/static /opt/app-root/src
# group 0 damit openshift unter einer "zufaelligen" user id fahren kann.
# dieser user hat nur im container namespace group 0.
RUN chgrp -R 0 /opt/app-root/src/ && chmod -R g+rwX /opt/app-root/src/
# nur zur sicherheit, falls der container doch mit der angebebenen uid ausgefuehrt wird
USER 1001
# Run script uses standard ways to run the application
CMD nginx -g "daemon off;"


