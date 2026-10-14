class ScenePreset {
  const ScenePreset(
    this.id,
    this.label,
    this.asset,
    this.caption, {
    this.poster,
  });
  final String id;
  final String label;
  final String asset;
  final String caption;
  final String? poster;
  bool get isVideo => poster != null;
  String get preview => poster ?? asset;
}

abstract final class SceneCatalog {
  static const scenes = <ScenePreset>[
    ScenePreset("study", "静谧书房", "assets/scenes/study.png", "一页书，一杯茶，一个片刻。"),
    ScenePreset(
      "clothesline",
      "蓝天晾衣绳",
      "assets/scenes/reverse_loops/01_reverse_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/01.jpg",
    ),
    ScenePreset(
      "still_02",
      "麦田相拥",
      "assets/scenes/stills/02.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "forest_steps",
      "林间石阶",
      "assets/scenes/reverse_loops/07_reverse_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/07.jpg",
    ),
    ScenePreset(
      "forest_train",
      "林间列车",
      "assets/scenes/forward_loops/08_forward_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/08.jpg",
    ),
    ScenePreset(
      "still_11",
      "深夜工作室",
      "assets/scenes/stills/11.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "cloud_swing",
      "云上秋千",
      "assets/scenes/reverse_loops/13_reverse_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/13.jpg",
    ),
    ScenePreset(
      "still_14",
      "阳台烟花",
      "assets/scenes/stills/14.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_15",
      "晚霞云朵",
      "assets/scenes/stills/15.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_16",
      "彩色窗格",
      "assets/scenes/stills/16.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_17",
      "蓝色蝴蝶房间",
      "assets/scenes/stills/17.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_18",
      "紫色冰箱",
      "assets/scenes/stills/18.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_19",
      "悬空楼宇",
      "assets/scenes/stills/19.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_20",
      "旧楼天井",
      "assets/scenes/stills/20.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_21",
      "复古唱片",
      "assets/scenes/stills/21.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "pool",
      "泳池漂浮",
      "assets/scenes/reverse_loops/22_reverse_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/22.jpg",
    ),
    ScenePreset(
      "still_23",
      "花卉拼贴",
      "assets/scenes/stills/23.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "sky_light",
      "天窗日光",
      "assets/scenes/forward_loops/24_forward_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/24.jpg",
    ),
    ScenePreset(
      "balcony",
      "阳台休息",
      "assets/scenes/stills/25.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "still_26",
      "蓝色楼梯",
      "assets/scenes/stills/26.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "cloud_rest",
      "云端休息",
      "assets/scenes/reverse_loops/29_reverse_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/29.jpg",
    ),
    ScenePreset(
      "still_31",
      "彩色河流",
      "assets/scenes/stills/31.jpg",
      "和奶娃一起，安静片刻。",
    ),
    ScenePreset(
      "greenhouse_piano",
      "温室钢琴",
      "assets/scenes/reverse_loops/34_reverse_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/34.jpg",
    ),
    ScenePreset(
      "underwater_light",
      "水下光束",
      "assets/scenes/forward_loops/35_forward_60fps.mp4",
      "和奶娃一起，安静片刻。",
      poster: "assets/scenes/posters/35.jpg",
    ),
    ScenePreset(
      'riverside',
      '河畔午后',
      'assets/scenes/riverside.png',
      '把目光留在阳光里。',
    ),
    ScenePreset(
      'coronation',
      '金色礼堂',
      'assets/scenes/coronation.png',
      '给平常的一天，一点光。',
    ),
    ScenePreset('academy', '拱廊漫谈', 'assets/scenes/academy.png', '想法会在安静里生长。'),
    ScenePreset(
      'garden_swing',
      '花园秋千',
      'assets/scenes/garden_swing.png',
      '风吹过花园，也吹过心间。',
    ),
    ScenePreset(
      'golden_light',
      '光中片刻',
      'assets/scenes/golden_light.png',
      '停一下，感受这一束光。',
    ),
    ScenePreset(
      'cloud_music',
      '云间乐章',
      'assets/scenes/cloud_music.png',
      '让思绪轻一些。',
    ),
    ScenePreset(
      'library',
      '暖光书馆',
      'assets/scenes/library.png',
      '一本书，一个想法，一点时间。',
    ),
    ScenePreset(
      'mountain_ride',
      '山间旅程',
      'assets/scenes/mountain_ride.png',
      '每一步，都走向新的风景。',
    ),
    ScenePreset(
      'starry_night',
      '奶娃星夜',
      'assets/scenes/starry_night.png',
      '夜色渐深，心绪渐静。',
    ),
  ];

  static ScenePreset byId(String id) =>
      scenes.firstWhere((scene) => scene.id == id);
}
