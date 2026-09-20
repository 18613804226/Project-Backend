FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

# 1. 设置国内镜像源与超时参数
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install -g pnpm

RUN pnpm config set registry https://registry.npmmirror.com

# 2. 复制所有源码
COPY . .

# 3. 安装所有依赖（包含开发依赖，会自动触发 prisma generate）
RUN pnpm install --frozen-lockfile=false

# 4. 执行编译（这一步会稳稳生成 dist 目录）
RUN pnpm run build

# 5. 生产运行阶段
EXPOSE 3000

# 直接用 node 运行编译后的产物
CMD ["node", "dist/src/main.js"]