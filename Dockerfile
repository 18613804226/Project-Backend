# 1. 编译阶段
FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

# 核心：在容器内强制全局更换国内淘宝镜像源，并调高超时时间
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install -g pnpm

RUN pnpm config set registry https://registry.npmmirror.com

# 复制依赖配置文件
COPY package.json pnpm-lock.yaml* ./

# 安装所有依赖（包含开发依赖用于打包）
RUN pnpm install --frozen-lockfile=false

# 复制源码并编译
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
# 仅安装生产环境依赖，并跳过会报错的脚本
RUN pnpm install --prod --ignore-scripts

# 复制编译后的产物
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

EXPOSE 3000
CMD ["node", "dist/main.js"]