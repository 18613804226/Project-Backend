# 1. 编译阶段
FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

# 直接通过 npm 全局安装稳定版的 pnpm
RUN npm install -g pnpm

# 复制依赖配置文件
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

# 复制源码并编译
COPY . .
RUN npx prisma generate
RUN pnpm run build

# 2. 运行阶段
FROM dockerproxy.net/library/node:20-alpine
WORKDIR /app

RUN npm install -g pnpm

COPY package.json pnpm-lock.yaml* ./
# 仅安装生产环境依赖
RUN pnpm install --prod

# 复制编译后的产物
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

EXPOSE 3000
CMD ["node", "dist/main.js"]