"""Package the supplied icon unchanged into native icon sizes and formats."""
import json
from pathlib import Path
from PIL import Image

app = Path(__file__).resolve().parents[1] / 'app'
source = Image.open(app / 'assets/brand/app_icon.png').convert('RGB')

def icon(size):
    return source.resize((size, size), Image.Resampling.LANCZOS)

for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    icon(size).save(app / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
for platform in ('ios', 'macos'):
    folder = app / f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((folder / 'Contents.json').read_text(encoding='utf8'))['images']:
        if entry.get('filename'):
            size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
            icon(size).save(folder / entry['filename'])
icon(256).save(app / 'windows/runner/resources/app_icon.ico', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
print('Supplied Nai Long icon packaged for all four platforms.')
