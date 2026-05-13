# Etapa 1: Dependencias
FROM node:20-alpine AS deps
# Instalamos libc6-compat porque algunas librerías de Node (como Prisma o Sharp) la necesitan en Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# Etapa 2: Constructor (Build)
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Etapa 3: Producción (Imagen Final)
FROM node:20-alpine AS runner
WORKDIR /app

# Seteamos el entorno a producción
ENV NODE_ENV production

# Creamos un usuario no-root por seguridad
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src

# Usar el usuario creado
USER nodejs

EXPOSE 3000

CMD ["node", "src/index.js"]