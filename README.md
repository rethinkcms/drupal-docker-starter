# Drupal Docker Starter

A starter template for setting up a Drupal development environment using Docker and Docker Compose. This repository includes everything you need to quickly launch and develop Drupal sites with minimal configuration.

## Getting Started

### Prerequisites

- Docker
- Docker Compose

### Setup

1. Clone the repository:
   ```sh
   git clone https://github.com/your-username/drupal-docker-starter.git
   cd drupal-docker-starter
   ```

2. Place your `composer.json` file and any other necessary files in the `app` directory.

3. Start the Docker containers:
   ```sh
   docker compose up -d --build
   ```

4. Find the randomly assigned port:
   ```sh
   docker compose ps
   ```

5. Open your browser and navigate to `http://localhost:[random_port]` to access your Drupal site.

### Dynamic Code Changes

- Edit your `composer.json` and other files in the `app` directory as needed.

### Services

- **Drupal**: Accessible at `http://localhost:[random_port]`
- **MariaDB**: Accessible on the internal Docker network

### Volumes

- `db_data` is a named volume for the MariaDB data.

### Customization

- Modify the `Dockerfile` to install additional PHP extensions or other software as needed.
- Adjust the `docker-compose.yml` file to fit your requirements.

## Contributing

Feel free to open issues or submit pull requests with improvements.

## License

[MIT License](LICENSE)
```