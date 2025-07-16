#!/bin/bash

# إعدادات المستخدم والمشروع
GITHUB_USERNAME="AhmedHamdyEmarazz"
REPO_NAME="ocr-table-app2"
BASE_HREF="/$REPO_NAME/"

# تعديل سطر <base href> داخل web/index.html
INDEX_FILE="web/index.html"
if [ ! -f "$INDEX_FILE" ]; then
  echo "❌ لم يتم العثور على web/index.html"
  exit 1
fi

# تعديل أو إدراج base href
if grep -q "<base href=" "$INDEX_FILE"; then
  sed -i '' "s|<base href=.*>|<base href=\"$BASE_HREF\">|" "$INDEX_FILE"
  echo "✅ تم تعديل base href إلى $BASE_HREF"
else
  sed -i '' "/<head>/a\\
  <base href=\"$BASE_HREF\">
  " "$INDEX_FILE"
  echo "✅ تم إدراج base href داخل <head>"
fi

# تنفيذ build
echo "🚧 جاري تنفيذ build..."
flutter build web || { echo "❌ فشل build"; exit 1; }

# إنشاء مجلد مؤقت
TMP_DIR="./__gh_temp__"
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cp -r build/web/* "$TMP_DIR/"

# تهيئة git داخل المجلد المؤقت ورفع gh-pages
cd "$TMP_DIR"
git init
git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git
git checkout -b gh-pages
git add .
git commit -m "🔄 تحديث GitHub Pages تلقائيًا"
git push -f origin gh-pages

# العودة إلى مجلد المشروع
cd ..
rm -rf "$TMP_DIR"

echo "✅ تم نشر التطبيق على GitHub Pages:"
echo "🌍 https://$GITHUB_USERNAME.github.io/$REPO_NAME/"
#chmod +x safe_deploy.sh
#./safe_deploy.sh


#git checkout main



#cd "ocr_table_app2 copy 2"  #depend on file name

#git init
#git remote add origin https://github.com/AhmedHamdyEmarazz/ocr-table-app2.git
#git fetch
#git checkout main  # أو master حسب اسم الفرع