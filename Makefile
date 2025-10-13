USER_NAME=lsilva-x

VOLUME_DIRS=/home/$(USER_NAME)/data/mariadb /home/$(USER_NAME)/data/wordpress

DC_SOURCE_FILE=./srcs/docker-compose.yml

all: build up

build:
	docker compose -f $(DC_SOURCE_FILE) build --no-cache

create-dirs:
	mkdir -p $(VOLUME_DIRS)

up: create-dirs
	docker compose -f $(DC_SOURCE_FILE) up -d

down:
	docker compose -f $(DC_SOURCE_FILE) down

re: down up

clean :
	docker compose -f $(DC_SOURCE_FILE) down --volumes --remove-orphans

fclean :
	docker compose -f $(DC_SOURCE_FILE) down --volumes --remove-orphans --rmi all

.PHONY: up down re clean fclean all build create-dirs