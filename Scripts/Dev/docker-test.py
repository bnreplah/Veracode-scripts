import docker

client = docker.from_env()
print(client.containers.run("veracode/pipeline-scan:cmd","--file veradeo.war"))