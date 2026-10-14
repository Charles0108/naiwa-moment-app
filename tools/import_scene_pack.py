"""Import the supplied three-folder scene pack and generate video posters."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
parser.add_argument('--ffmpeg', default='ffmpeg')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
target = root / 'app/assets/scenes'
manifest = json.loads((args.source / 'manifest.json').read_text(encoding='utf8'))
ids = {'01':'clothesline', '07':'forest_steps', '08':'forest_train', '13':'cloud_swing', '22':'pool', '24':'sky_light', '25':'balcony', '29':'cloud_rest', '34':'greenhouse_piano', '35':'underwater_light'}
catalog = root / 'app/lib/core/scene_catalog.dart'
old = catalog.read_text(encoding='utf8')
# Keep the ten existing paintings; remove the replaced eight old videos/posters.
for path in [*target.glob('*.mp4'), *target.glob('*_poster.jpg')]:
    path.unlink()
entries = []
for scene in manifest['assets']:
    source = args.source / scene['file']
    destination = target / scene['file']
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    scene_id = ids.get(scene['id'], 'still_'+scene['id'])
    asset = 'assets/scenes/'+scene['file']
    poster = None
    if scene['kind'] != 'still':
        poster_file = target / 'posters' / (scene['id']+'.jpg')
        poster_file.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([args.ffmpeg, '-y', '-loglevel', 'error', '-i', str(source), '-frames:v', '1', '-vf', 'scale=720:-2', '-q:v', '3', str(poster_file)], check=True)
        poster = 'assets/scenes/posters/'+scene['id']+'.jpg'
    quote = lambda value: json.dumps(value, ensure_ascii=False)
    fields = ', '.join(quote(value) for value in (scene_id, scene['name'], asset, '和奶娃一起，安静片刻。'))
    entries.append('    ScenePreset('+fields+(', poster: '+quote(poster) if poster else '')+'),')
    scene['appId'] = scene_id
    scene['asset'] = asset
    if poster: scene['poster'] = poster
manifest['creator'] = '防御老猫'
manifest['videoTitle'] = '【奶娃】“悲观人生”'
manifest['sourceVideoId'] = 'BV1ijHp6jEo9'
(target / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
# Retain the original painting entries after the replaced video section.
art_start = old.index("    ScenePreset(\n      'riverside'")
art_end = old.index('  ];', art_start)
art = old[art_start:art_end]
prefix = old[:old.index('  static const scenes =')]
body = '  static const scenes = <ScenePreset>[\n    ScenePreset("study", "静谧书房", "assets/scenes/study.png", "一页书，一杯茶，一个片刻。"),\n'+'\n'.join(entries)+'\n'+art+'  ];\n\n  static ScenePreset byId(String id) =>\n      scenes.firstWhere((scene) => scene.id == id);\n}\n'
catalog.write_text(prefix+body, encoding='utf8')
print(f'Imported {len(entries)} supplied scenes; retained 10 paintings. Total: 33.')
