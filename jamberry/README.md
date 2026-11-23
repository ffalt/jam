# JamBerry development

See the [root README](../README.md) for installation and server configuration. Run the following commands from `jamberry/` after installing dependencies.

| Command | Purpose |
| --- | --- |
| `npm start` | Start the development server at `http://localhost:4200/` with automatic reload |
| `npm run build` | Build into `dist/` |
| `npm run build:prod` | Build in production mode into `dist/` |
| `npm run clean` | Remove `dist/` |
| `npm test` | Run unit tests with Vitest |
| `npm run test:watch` | Run tests in watch mode |
| `npm run test:coverage` | Generate a test coverage report |
| `npm run lint` | Run the Angular and ESLint checks |

The development server proxies API requests to JamServe at `http://localhost:4040/`; start the server separately. Its development configuration supplies the `admin`/`admin` credentials, so update `proxy.conf.mjs` if your local credentials differ.
