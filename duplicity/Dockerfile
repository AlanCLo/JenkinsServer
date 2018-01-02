FROM postgres

RUN mkdir -p /workspace
WORKDIR /workspace
ADD . /workspace
RUN sh install-dependencies.sh --nopsql

VOLUME /workspace/backup_folder

CMD ["cron", "-f"]
