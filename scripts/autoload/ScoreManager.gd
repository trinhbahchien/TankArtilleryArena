extends Node

## Quản lý Tính Điểm Quân Sự, Lưu Trữ Kỷ Lục và Thông Tin 10 Màn Chơi
## - Công thức tính điểm tốc độ: Đánh càng nhanh, Thưởng Thời Gian (Time Bonus) càng cực cao!
## - Xếp hạng chiến thuật chuẩn quân sự: S (Huyền thoại) / A (Chuyên gia) / B (Ưu tú) / C (Hoàn thành)
## - Lưu trữ vĩnh viễn trên đĩa qua user://tank_scores.cfg

const SAVE_PATH := "user://tank_scores.cfg"

var level_configs: Dictionary = {
	1: {
		"title": "Tân Binh Pháo Thủ",
		"target_time": 45.0,
		"desc": "Làm quen hỏa lực pháo cối và súng máy diệt 2 xe tăng trinh sát.",
		"scene": "res://scenes/levels/Level1.tscn"
	},
	2: {
		"title": "Vượt Chướng Ngại Vật",
		"target_time": 50.0,
		"desc": "Bắn nổ hàng rào, kích hoạt phuy xăng tiêu diệt cụm 3 xe địch.",
		"scene": "res://scenes/levels/Level2.tscn"
	},
	3: {
		"title": "Mê Cung Khói Mù",
		"target_time": 55.0,
		"desc": "Sử dụng Radar quét xuyên màn khói dày đặc để phá ổ phục kích.",
		"scene": "res://scenes/levels/Level3.tscn"
	},
	4: {
		"title": "Hỏa Lực Chéo 3 Phía",
		"target_time": 60.0,
		"desc": "Vận dụng kỹ năng thả khói [E] và tự sửa [Q] chống gọng kìm 4 xe.",
		"scene": "res://scenes/levels/Level4.tscn"
	},
	5: {
		"title": "Đại Chiến Trùm Mammoth",
		"target_time": 75.0,
		"desc": "Quyết đấu Siêu Trùm Mammoth 350 HP sở hữu hỏa lực nòng pháo đôi.",
		"scene": "res://scenes/levels/Level5.tscn"
	},
	6: {
		"title": "Thung Lũng Xạ Thủ",
		"target_time": 65.0,
		"desc": "Đối đầu dàn Xe tăng Bắn tỉa (Sniper Tank) ngắm Laser tử thần.",
		"scene": "res://scenes/levels/Level6.tscn"
	},
	7: {
		"title": "Cơn Mưa Tên Lửa",
		"target_time": 65.0,
		"desc": "Né tránh bão Rocket đạn đạo tầm xa và phản công chớp nhoáng.",
		"scene": "res://scenes/levels/Level7.tscn"
	},
	8: {
		"title": "Pháo Đài Bê Tông",
		"target_time": 70.0,
		"desc": "Đột kích cứ điểm kiên cố phối hợp cả Sniper lẫn Rocket địch.",
		"scene": "res://scenes/levels/Level8.tscn"
	},
	9: {
		"title": "Chiến Dịch Blitzkrieg",
		"target_time": 70.0,
		"desc": "Tổng tấn công hỏa lực dồn dập, thử thách khả năng sấy súng máy và pháo.",
		"scene": "res://scenes/levels/Level9.tscn"
	},
	10: {
		"title": "Trận Chiến Cuối Cùng: Siêu Pháo Đài",
		"target_time": 95.0,
		"desc": "Siêu trùm Mammoth tối thượng được hộ tống bởi quân đoàn tinh nhuệ!",
		"scene": "res://scenes/levels/Level10.tscn"
	}
}

var last_match_result: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func calculate_score(level_num: int, clear_time: float, kills: int, hp_ratio: float) -> Dictionary:
	var cfg: Dictionary = level_configs.get(level_num, { "target_time": 60.0, "title": "Chiến Dịch" })
	var target_t: float = float(cfg.get("target_time", 60.0))
	
	var base_score: int = 5000
	# THƯỞNG TỐC ĐỘ: Hoàn thành nhanh hơn mục tiêu -> Thưởng 150 điểm/giây tiết kiệm được
	var time_saved: float = maxf(target_t - clear_time, 0.0)
	var time_bonus: int = int(time_saved * 150.0)
	
	# THƯỞNG TIÊU DIỆT: 1200 điểm mỗi xe địch
	var kill_bonus: int = kills * 1200
	
	# THƯỞNG BẢO TOÀN GIÁP: Tối đa 2500 điểm nếu còn 100% máu
	var hp_bonus: int = int(clampf(hp_ratio, 0.0, 1.0) * 2500.0)
	
	# HỆ SỐ TỐC ĐỘ BÀN THỜ: Nếu xong dưới 60% thời gian mục tiêu -> Nhân hệ số 1.35x
	var speed_multiplier: float = 1.0
	if clear_time <= target_t * 0.6:
		speed_multiplier = 1.35
	elif clear_time <= target_t * 0.85:
		speed_multiplier = 1.15
		
	var total_score: int = int((base_score + time_bonus + kill_bonus + hp_bonus) * speed_multiplier)
	
	# Xếp hạng chiến thuật
	var rank: String = "C"
	if total_score >= 12000:
		rank = "S"
	elif total_score >= 9000:
		rank = "A"
	elif total_score >= 6500:
		rank = "B"
	else:
		rank = "C"

	# ĐÁNH GIÁ HỆ THỐNG SAO CHIẾN DỊCH (Tối đa 5 Sao - Max Cấp)
	# 1 Sao: Hoàn thành nhiệm vụ (Tiêu diệt toàn bộ xe địch)
	# 2 Sao: Hiệu suất chiến đấu khá (>= 7000 điểm)
	# 3 Sao: Hoàn thành đúng tiến độ thời gian (clear_time <= target_time hoặc >= 9500 điểm)
	# 4 Sao: Cơ động xuất sắc & bảo toàn chiến xa (clear_time <= target_t * 0.85 & hp_ratio >= 0.50, hoặc >= 12000 điểm)
	# 5 Sao: THẦN TỐC & VÔ SONG - MAX CẤP (clear_time <= target_t * 0.70 & hp_ratio >= 0.75, hoặc >= 14500 điểm)
	var stars: int = 1
	if total_score >= 14500 or (clear_time <= target_t * 0.70 and hp_ratio >= 0.75):
		stars = 5
	elif total_score >= 12000 or (clear_time <= target_t * 0.85 and hp_ratio >= 0.50):
		stars = 4
	elif total_score >= 9500 or (clear_time <= target_t):
		stars = 3
	elif total_score >= 7000:
		stars = 2
	else:
		stars = 1

	# Kiểm tra và ghi nhận Kỷ lục mới
	var prev_best: Dictionary = get_level_best(level_num)
	var prev_score: int = int(prev_best.get("score", 0))
	var prev_stars: int = int(prev_best.get("stars", 0))
	var is_record: bool = (total_score > prev_score or stars > prev_stars)
	if is_record:
		save_level_record(level_num, total_score, rank, stars)

	last_match_result = {
		"level": level_num,
		"title": cfg.get("title", "Chiến dịch"),
		"clear_time": clear_time,
		"target_time": target_t,
		"time_bonus": time_bonus,
		"kill_bonus": kill_bonus,
		"hp_bonus": hp_bonus,
		"speed_multiplier": speed_multiplier,
		"total_score": total_score,
		"rank": rank,
		"stars": stars,
		"is_max_level": (stars == 5),
		"is_new_record": is_record
	}
	
	return last_match_result

func save_level_record(level_num: int, score: int, rank_str: String, star_count: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # Nạp nếu đã có
	var cur_score: int = int(cfg.get_value("scores", "level_%d_score" % level_num, 0))
	var cur_stars: int = int(cfg.get_value("scores", "level_%d_stars" % level_num, 0))
	if score > cur_score:
		cfg.set_value("scores", "level_%d_score" % level_num, score)
		cfg.set_value("scores", "level_%d_rank" % level_num, rank_str)
	if star_count > cur_stars:
		cfg.set_value("scores", "level_%d_stars" % level_num, star_count)
	cfg.save(SAVE_PATH)

func get_level_best(level_num: int) -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return { "score": 0, "rank": "--", "stars": 0 }
	var s: int = int(cfg.get_value("scores", "level_%d_score" % level_num, 0))
	var r: String = str(cfg.get_value("scores", "level_%d_rank" % level_num, "--"))
	var st: int = int(cfg.get_value("scores", "level_%d_stars" % level_num, 0))
	return { "score": s, "rank": r, "stars": st }

func get_total_stars() -> int:
	var total: int = 0
	for i in range(1, 11):
		var best: Dictionary = get_level_best(i)
		total += int(best.get("stars", 0))
	return total

func get_stars_display(star_count: int) -> String:
	if star_count >= 5:
		return "[5/5 SAO - MAX CẤP]"
	return "[%d/5 SAO]" % star_count

func get_stars_emoji(star_count: int) -> String:
	if star_count >= 5:
		return "[5/5 SAO - MAX CẤP]"
	return "[%d/5 SAO]" % star_count

func get_level_info(level_num: int) -> Dictionary:
	var info: Dictionary = level_configs.get(level_num, {})
	var best := get_level_best(level_num)
	info["best_score"] = best["score"]
	info["best_rank"] = best["rank"]
	info["best_stars"] = best["stars"]
	return info
