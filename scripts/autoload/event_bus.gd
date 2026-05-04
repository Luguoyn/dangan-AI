extends Node

# ============================================================
# EventBus — 全局事件总线 (Autoload)
# 所有模块通过 EventBus 通信，不直接依赖彼此
# ============================================================

# --- 对话相关 ---
signal dialogue_show(data: Dictionary)
signal dialogue_next

# --- 证据相关 ---
signal evidence_added(evidence_id: String)
signal evidence_updated(evidence_id: String)
signal evidence_removed(evidence_id: String)

# --- 精神力/HP 相关 ---
signal hp_changed(current: int, max_hp: int)
signal hp_depleted

# --- 小游戏完成信号 ---
signal nonstop_debate_finished(is_success: bool)
signal rebuttal_finished(is_success: bool)
signal hangman_finished(is_success: bool)
signal climax_inference_finished(is_success: bool)

# --- 选择/分支 ---
signal choice_presented(data: Dictionary)
signal choice_made(choice_index: int)

# --- 场景相关 ---
signal scene_load_requested(scene_path: String)
signal scene_loaded(scene_id: String)

# --- 剧本执行 ---
signal command_executed(cmd_id: String)
signal script_finished(script_id: String)

# --- NPC / 交互 ---
signal npc_interacted(character_id: String)
signal investigation_point_clicked(point_id: String)

# --- 技能相关 ---
signal skill_selected(skill_ids: Array)
signal skill_equipped(skill_id: String)
signal skill_unequipped(skill_id: String)

# --- 裁判流程 ---
signal trial_started
signal trial_ended(result: String)
signal start_nonstop_debate(config_id: String)
signal start_rebuttal(config_id: String)
signal start_hangman(config_id: String, mode: String)
signal start_climax_inference(config_id: String)

# --- BGM / 音效 ---
signal bgm_requested(action: String, bgm_id: String, volume: float, fade_duration: float)
signal sfx_requested(sfx_id: String, volume: float)

# --- 屏幕特效 ---
signal screen_effect_requested(effect: String, intensity: float, duration: float)

# --- 角色立绘 ---
signal show_character_requested(char_id: String, expression: String, position: String)
signal hide_character_requested(char_id: String)

# --- 背景 ---
signal background_change_requested(bg_id: String, transition: String)

# --- UI 提示 ---
signal save_prompt_requested(text: String)
signal skill_select_requested
