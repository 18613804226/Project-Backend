// prisma/seed.ts
import dotenv from 'dotenv';

// 1. 显式加载 .env.development（优先）和 .env（兜底）
dotenv.config({ path: '.env.development' });
dotenv.config();

import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

// 2. 指向你生成的真实客户端路径
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

// 3. 校验连接串，防止防错
const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error(
    '❌ 错误: DATABASE_URL 未定义，请检查 .env.development 配置文件！',
  );
  process.exit(1);
}

// 创建 PostgreSQL 连接池
const pool = new Pool({
  connectionString,
  ssl: false,
});

// 创建 Prisma Adapter
const adapter = new PrismaPg(pool);

// 传入 adapter 实例化 PrismaClient
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🌱 开始执行 seed 脚本...');

  // 检查 admin 是否存在
  const adminExists = await prisma.user.findFirst({
    where: { username: 'admin' },
  });

  if (!adminExists) {
    const hashedPassword = await bcrypt.hash('123456', 10);
    await prisma.user.create({
      data: {
        username: 'admin',
        password: hashedPassword,
        role: 'ADMIN',
      },
    });
    console.log('✅ 成功创建管理员用户: admin / 123456');
  } else {
    console.log('ℹ️ 管理员用户已存在，跳过创建');
  }

  console.log('✅ Seed 脚本执行完毕');
}

main()
  .catch((e) => {
    console.error('❌ Seed 执行失败:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    // 关闭连接池，避免进程挂起
    await pool.end();
  });
