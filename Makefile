build:
	docker compose build

start:
	docker compose up

stop:
	docker compose down

clean:
	docker compose down -v

flag:
	docker build -t flag_tool -f Dockerfile.flag_tool . && \
	docker run -it -v minitwit_minitwit:/data flag_tool
