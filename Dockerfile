# 1. 编译阶段
FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

# 设置国内镜像源与超时参数
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install -g pnpm

RUN pnpm config set registry https://registry.npmmirror.com

# 复制所有源码
COPY . .

# 安装依赖并自动触发 prisma generate
RUN pnpm install --frozen-lockfile=false

# 编译打包
RUN pnpm run build

# 2. 运行阶段（直接继承编译好的成果，不再重复安装）
FROM dockerproxy.net/library/node:20-alpine
WORKDIR /app

# 复制编译阶段生成好的产物和依赖
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["node", "dist/main.js"]