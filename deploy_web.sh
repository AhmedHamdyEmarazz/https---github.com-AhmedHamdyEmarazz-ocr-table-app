#!/bin/bash

echo "🔧 جاري بناء نسخة Flutter Web..."
flutter build web

echo "🌿 الانتقال إلى فرع gh-pages..."
git checkout gh-pages || git checkout --orphan gh-pages

echo "🧹 حذف الملفات القديمة..."
git rm -rf .

echo "📂 نسخ ملفات build/web إلى الجذر..."
cp -r build/web/* .

echo "📦 إضافة الملفات إلى Git..."
git add .

echo "✅ عمل Commit للتعديلات..."
git commit -m "نشر النسخة الجديدة على gh-pages"

echo "🚀 رفع التعديلات إلى GitHub Pages..."
git push origin gh-pages --force

echo "↩️ العودة إلى فرع main..."
git checkout main

echo "🎉 تم النشر بنجاح على GitHub Pages!"