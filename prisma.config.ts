// prisma.config.ts
import dotenv from 'dotenv';
import { defineConfig, env } from 'prisma/config';

// 显式指定加载 .env.development，再加载 .env 兜底
dotenv.config({ path: '.env.development' });
dotenv.config();

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: process.env.DATABASE_URL, // 注意：不是 env('...')，是直接取 process.env
  },
});
