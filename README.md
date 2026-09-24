<div align="center">

<img src="https://raw.githubusercontent.com/Hartwell-Labs/.github/main/profile/assets/hartwell-logo.svg" width="72" alt="Hartwell Labs" />

## Products Registry

Machine-readable index of every Hartwell Labs product — repos, packages, containers.

[![Ruby](https://img.shields.io/badge/Ruby-Sinatra%20·%20MongoDB-F15A24?style=flat-square&logo=ruby)](.) [![API](https://img.shields.io/badge/API-live-2cb67d?style=flat-square)](.)
[![License](https://img.shields.io/badge/license-MIT-F15A24?style=flat-square)](LICENSE) [![Website](https://img.shields.io/badge/site-hartwell--labs.github.io-4f46e5?style=flat-square)](https://hartwell-labs.github.io)

[Website](https://hartwell-labs.github.io) · [All products](https://hartwell-labs.github.io/products/) · [Security](https://hartwell-labs.github.io/security/) · [Hack the Lab](https://github.com/Hartwell-Labs/hack-the-lab)

</div>

> **"Which of these tools is actually a Hartwell Labs product?"** — this API is the answer.
> One machine-readable index of every Hartwell Labs product: source repos, published
> packages (PyPI / npm / GitHub Packages) and containers (GHCR), wherever they live.

Built for [Hartwell Labs](https://hartwell-labs.github.io) — an independent open-source
lab behind [talus](https://github.com/BartoszOsiej/talus-process-monitor) (eBPF ransomware
detection), [externum](https://github.com/BartoszOsiej/externum) (a typed language that
compiles to Python/Bash/bytecode) and [Aurora OS](https://github.com/BartoszOsiej/Aurora)
(a full desktop environment in the browser).

A Hartwell Labs product. Ruby · Sinatra · MongoDB Atlas.

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | API index / self-description |
| `GET` | `/health` | Liveness + database connectivity |
| `GET` | `/products` | All products. Filters: `?registry=pypi` (packages or containers), `?lang=rust`, `?all=true` |
| `GET` | `/products/:slug` | One product, e.g. `/products/talus-process-monitor` |

```console
$ curl -s https://<host>/products/externum | jq .tagline
"A typed language that compiles to Python, Bash and native bytecode"
```

## Run it

```bash
# 1. dependencies
bundle install   # or: gem install sinatra mongo webrick

# 2. credentials (MongoDB Atlas SRV URI)
export MONGODB_URI="mongodb+srv://user:pass@cluster0.xxx.mongodb.net"

# 3. seed the catalog (idempotent — replaces the collection)
ruby scripts/seed.rb

# 4. serve
ruby app.rb          # listens on :4576
```

## Data model

Source of truth: [`data/products.json`](data/products.json). Each product:

```jsonc
{
  "slug": "talus-process-monitor",
  "repo": "https://github.com/BartoszOsiej/talus-process-monitor",
  "packages": [ { "registry": "pypi", "name": "talus-process-monitor", "version": "0.8.2", "url": "..." } ],
  "containers": [ { "registry": "ghcr", "image": "ghcr.io/hartwell-labs/talus-process-monitor", "tags": ["latest"] } ]
}
```

Edit `data/products.json`, re-run `ruby scripts/seed.rb`, done — the API never holds
state that isn't in the repo. Registry, database and collection names are configurable
via `MONGODB_DB` / `MONGODB_COLLECTION` env vars.

## License

MIT — part of the Hartwell Labs toolset. Security reports: see
[hack-the-lab](https://github.com/Hartwell-Labs/hack-the-lab) (safe harbor).
---

<div align="center">

**[Hartwell Labs](https://github.com/Hartwell-Labs)** — security systems, languages and tools, built in the open.

[Website](https://hartwell-labs.github.io) · [All products](https://hartwell-labs.github.io/products/) · [Security policy](https://hartwell-labs.github.io/security/) · [Report a vulnerability](https://hartwell-labs.github.io/security/)

<sub>MIT License · © 2026 Hartwell Labs</sub>

</div>
