# 1. 编译阶段
FROM dockerproxy.net/library/node:20-alpine AS builder
WORKDIR /app

# 设置国内镜像源与超时参数
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm install -g pnpm

RUN pnpm config set registry https://registry.npmmirror.com

# 【关键调整】先把所有源码（包含 prisma 文件夹和 package.json）一次性复制进来
COPY . .

# 安装所有依赖（此时因为 prisma 文件已经存在，postinstall 的 prisma generate 会自动成功执行）
RUN pnpm install --frozen-lockfile=false

# 编译打包
RUN pnpm run build

# 2. 运行阶段
FROM dockerproxy.net/library/node:20-alpine
WORKDIR /app

RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g pnpm

RUN pnpm config set registry https://registry.npmmirror.com

COPY package.json pnpm-lock.yaml* ./
# 仅安装生产环境依赖，并跳过脚本
RUN pnpm install --prod --ignore-scripts

# 复制编译后的产物
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

EXPOSE 3000
CMD ["node", "dist/main.js"]