# 1. 编译阶段
FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

# 设置 npm 国内镜像源，并全局安装 pnpm
RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g pnpm

# 给编译阶段的 pnpm 也配置国内镜像源
RUN pnpm config set registry https://registry.npmmirror.com

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

# 在第二阶段同样先换 npm 镜像源，并安装 pnpm
RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g pnpm

# 【关键修复】给运行阶段的 pnpm 也配置国内镜像源，解决下载依赖慢/超时的问题
RUN pnpm config set registry https://registry.npmmirror.com

COPY package.json pnpm-lock.yaml* ./
# 仅安装生产环境依赖
RUN pnpm install --prod

# 复制编译后的产物
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

EXPOSE 3000
CMD ["node", "dist/main.js"]