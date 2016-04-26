FROM python:2.7.11

ADD fake-https-server.py /opt/server/fake-https-server.py
ADD fake_server.pem /opt/server/fake_server.pem

WORKDIR /opt/server
ENTRYPOINT ["python", "fake-https-server.py"]
