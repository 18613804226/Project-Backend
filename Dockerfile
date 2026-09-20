FROM node:20-alpine
WORKDIR /app

# 复制配置文件和本地已经打包好的产物
COPY package.json pnpm-lock.yaml* ./
COPY dist ./dist
COPY prisma ./prisma
COPY node_modules/.prisma ./node_modules/.prisma

# 配置国内镜像并仅安装生产依赖
RUN npm config set registry https://registry.npmmirror.com \
    && npm install --omit=dev --ignore-scripts

EXPOSE 3000
CMD ["node", "dist/main.js"]