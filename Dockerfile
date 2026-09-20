# 1. 编译阶段
FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g pnpm
RUN pnpm config set registry https://registry.npmmirror.com

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .
RUN npx prisma generate
RUN pnpm run build

# 2. 运行阶段
FROM dockerproxy.net/library/node:20-alpine
WORKDIR /app

RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g pnpm
RUN pnpm config set registry https://registry.npmmirror.com

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --prod --ignore-scripts

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

EXPOSE 3000
CMD ["node", "dist/main.js"]