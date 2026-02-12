FROM oven/bun:latest AS builder
WORKDIR /app

# Copy workspace root files
COPY package.json bun.lock tsconfig.base.json ./

# Copy workspace package.json files for dependency resolution
COPY shared/package.json shared/
COPY hub/package.json hub/
COPY web/package.json web/
COPY cli/package.json cli/

# Stub missing workspaces (website, docs) so bun resolves all entries
RUN mkdir -p website docs \
 && echo '{"name":"hapi-website","private":true}' > website/package.json \
 && echo '{"name":"hapi-docs","private":true}' > docs/package.json

# Install dependencies
RUN bun install

# Copy source code
COPY shared/ shared/
COPY hub/ hub/
COPY web/ web/

# Build web frontend
RUN cd web && bun run build

# ---

FROM oven/bun:latest
WORKDIR /app

COPY --from=builder /app/node_modules/ node_modules/
COPY --from=builder /app/package.json .
COPY --from=builder /app/tsconfig.base.json .
COPY --from=builder /app/shared/ shared/
COPY --from=builder /app/hub/ hub/
COPY --from=builder /app/web/dist/ web/dist/

ENV HAPI_HOME=/data
ENV HAPI_LISTEN_HOST=0.0.0.0

EXPOSE 3006

CMD ["bun", "run", "hub/src/index.ts"]
