<script setup lang="ts">
import type { FoodAnalysisResult } from '~/shared/analysis'
import { getScoreTone } from '~/shared/analysis'

const props = defineProps<{
  result: FoodAnalysisResult | null
}>()

const demoResult: FoodAnalysisResult = {
  foodName: '风味酸乳',
  ingredients: [],
  healthScore: 5,
  compliance: {
    status: '合规',
    description: '配料及过敏原表达较清晰，未见明显违规表述。',
    issues: []
  },
  processing: {
    level: '较高',
    description: '含糖和多种风味、稳定类成分，整体更偏加工型乳制品。',
    score: 4
  },
  claims: {
    detectedClaims: ['风味酸乳'],
    supportedClaims: ['乳制品属性明确'],
    questionableClaims: [],
    assessment: '宣传信息较克制，重点仍应关注真实配料构成。'
  },
  overallAssessment: '这类产品可以偶尔饮用，但不适合作为日常高频乳制品替代纯酸奶。',
  recommendations: '如果你在控糖、减脂或关注儿童日常糖摄入，建议优先选择配料更简单、含糖更低的产品。',
  warnings: [
    '白砂糖会明显抬高糖负担，控糖人群不建议高频摄入。',
    '食用香精说明产品风味修饰较强，可优先比较配料更简单的同类产品。'
  ],
  analysisTime: new Date().toISOString(),
  rawMarkdown: "## 生牛乳\n- 作用: 主要原料，提供蛋白质、钙等基础营养\n- 安全: 合规✅ 加工度 低 🥛 天然乳品，需注意新鲜度\n- 提醒: 乳糖不耐受者需注意\n\n## 饮用水\n- 作用: 调节产品质地与浓度\n- 安全: 合规✅ 加工度 低 💧 基础溶剂，安全\n- 提醒: 无特别提醒\n\n## 草莓果酱\n- 作用: 提供草莓风味、色泽和部分糖分\n- 安全: 合规✅ 加工度 中 🍓 含添加糖，为风味来源\n- 提醒: 注意额外糖分摄入\n\n## 白砂糖\n- 作用: 提供甜味和能量\n- 安全: 合规✅ 加工度 中 🍬 常见甜味剂，需控制量\n- 提醒: 过量摄入不利健康\n\n## 佳宝\n- 作用: (信息不足，可能为品牌或特定成分)\n- 安全: 合规✅ 加工度 中 ⚠️ 具体成分不明\n- 提醒: 建议查询具体成分\n\n## 燕麦粒\n- 作用: 增加膳食纤维和谷物口感\n- 安全: 合规✅ 加工度 低 🌾 全谷物，营养有益\n- 提醒: 无特别提醒\n\n## 果葡糖浆\n- 作用: 甜味剂，提供能量和改善口感\n- 安全: 合规✅ 加工度 高 🍯 液态甜味剂，升糖较快\n- 提醒: 需控制摄入量\n\n## 乙酰化二淀粉磷酸酯\n- 作用: 增稠剂、稳定剂\n- 安全: 合规✅ 加工度 高 🧪 改性淀粉，安全\n- 提醒: 无特别提醒\n\n## 赤藓糖醇\n- 作用: 甜味剂，提供甜味几乎无热量\n- 安全: 合规✅ 加工度 高 🍬 代糖，耐受性佳\n- 提醒: 过量可能引起肠胃不适\n\n## 羧甲基纤维素钠\n- 作用: 增稠剂、稳定剂\n- 安全: 合规✅ 加工度 高 🧪 常见食品添加剂\n- 提醒: 无特别提醒\n\n## 果胶\n- 作用: 增稠剂、胶凝剂\n- 安全: 合规✅ 加工度 中 🍎 天然提取物，安全\n- 提醒: 无特别提醒\n\n## 结冷胶\n- 作用: 胶凝剂、稳定剂\n- 安全: 合规✅ 加工度 高 🧪 微生物发酵多糖\n- 提醒: 无特别提醒\n\n## 双甘油脂肪酸酯\n- 作用: 乳化剂，改善质地\n- 安全: 合规✅ 加工度 高 🧪 常见乳化剂\n- 提醒: 无特别提醒\n\n## 酸切\n- 作用: (信息不足，可能为酸度调节剂或笔误)\n- 安全: 合规✅ 加工度 中 ⚠️ 具体成分不明\n- 提醒: 建议查询具体成分\n\n## 柠檬酸钠\n- 作用: 酸度调节剂、稳定剂\n- 安全: 合规✅ 加工度 中 🍋 常见食品添加剂\n- 提醒: 无特别提醒\n\n## 双乙酰酒石酸单双甘油酯\n- 作用: 乳化剂，改善面团或质地\n- 安全: 合规✅ 加工度 高 🧪 常见乳化剂\n- 提醒: 无特别提醒\n\n## 三氯蔗糖\n- 作用: 高强度甜味剂\n- 安全: 合规✅ 加工度 高 🍬 人工甜味剂，甜度高\n- 提醒: 无特别提醒\n\n## 德氏\n- 作用: (信息不足，可能为菌种品牌或笔误)\n- 安全: 合规✅ 加工度 中 ⚠️ 具体成分不明\n- 提醒: 建议查询具体成分\n\n## 保加利亚乳杆菌\n- 作用: 发酵菌种，有益肠道\n- 安全: 合规✅ 加工度 低 🦠 常见益生菌\n- 提醒: 无特别提醒\n\n## 嗜热链球菌\n- 作用: 发酵菌种，产酸产香\n- 安全: 合规✅ 加工度 低 🦠 常见发酵菌\n- 提醒: 无特别提醒\n\n## 食用香精\n- 作用: 增强或补充产品风味\n- 安全: 合规✅ 加工度 高 🌸 人工调配，合规使用安全\n- 提醒: 无特别提醒"
}

interface ParsedIngredient {
  name: string
  function: string
  safety: string
  reminder: string
}

const activeResult = computed(() => props.result ?? demoResult)
const scoreTone = computed(() => getScoreTone(activeResult.value.healthScore))
const isDemo = computed(() => !props.result)

const parsedIngredients = computed(() => {
  const md = activeResult.value.rawMarkdown
  if (!md) return []
  
  const ingredients: ParsedIngredient[] = []
  const blocks = md.split(/\n(?=##)/)
  
  for (const block of blocks) {
    const lines = block.split('\n').filter(l => l.trim())
    if (lines.length === 0) continue
    
    const nameLine = lines[0]?.replace(/^##\s+/, '').trim()
    if (!nameLine) continue
    
    let functionText = ''
    let safetyText = ''
    let reminderText = ''
    
    for (const line of lines.slice(1)) {
      if (line.startsWith('- 作用:')) {
        functionText = line.replace(/^-\s+作用:\s*/, '').trim()
      } else if (line.startsWith('- 安全:')) {
        safetyText = line.replace(/^-\s+安全:\s*/, '').trim()
      } else if (line.startsWith('- 提醒:')) {
        reminderText = line.replace(/^-\s+提醒:\s*/, '').trim()
      }
    }
    
    ingredients.push({
      name: nameLine,
      function: functionText,
      safety: safetyText,
      reminder: reminderText
    })
  }
  
  return ingredients
})
</script>

<template>
  <div class="space-y-3">
    <!-- Hero: food name + chips + score -->
    <div class="rounded-2xl bg-gradient-to-br from-[#f3fbf4] to-[#e7f4e9] border border-[#d9e8db] p-4">
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <h2 class="text-xl font-bold text-slate-900 truncate">{{ activeResult.foodName }}</h2>
            <UBadge v-if="isDemo" color="neutral" variant="soft" size="sm">演示</UBadge>
          </div>
          <div class="mt-2 flex flex-wrap gap-1.5">
            <span
              class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold"
              :style="{ backgroundColor: scoreTone.softHex, color: scoreTone.hex }"
            >
              <UIcon name="i-lucide-heart" class="size-3" />
              {{ scoreTone.label }}
            </span>
            <span class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
              <UIcon name="i-lucide-shield-check" class="size-3" />
              {{ activeResult.compliance.status || '待分析' }}
            </span>
            <span class="inline-flex items-center gap-1 rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-600">
              <UIcon name="i-lucide-factory" class="size-3" />
              加工 {{ activeResult.processing.level || '待分析' }}
            </span>
          </div>
        </div>
        <div
          class="flex shrink-0 flex-col items-center justify-center w-14 h-14 rounded-2xl border"
          :style="{ backgroundColor: scoreTone.softHex, borderColor: scoreTone.borderHex }"
        >
          <span class="text-xl font-extrabold leading-none" :style="{ color: scoreTone.hex }">
            {{ activeResult.healthScore.toFixed(1) }}
          </span>
          <span class="text-[10px]" :style="{ color: scoreTone.hex + '99' }">/ 10</span>
        </div>
      </div>

      <p class="mt-2.5 text-[13px] leading-relaxed text-slate-600">
        {{ activeResult.overallAssessment }}
      </p>

      <!-- Warning / recommendations -->
      <div v-if="activeResult.recommendations" class="mt-2.5 flex gap-1.5 rounded-xl bg-amber-50/70 px-3 py-2">
        <UIcon name="i-lucide-triangle-alert" class="mt-0.5 size-3.5 shrink-0 text-amber-600" />
        <p class="text-xs leading-relaxed text-amber-800">{{ activeResult.recommendations }}</p>
      </div>
    </div>

    <!-- Ingredients -->
    <div class="rounded-2xl border border-[#dee9e0] bg-white p-3.5">
      <div class="flex items-center justify-between mb-3">
        <h3 class="text-base font-bold text-slate-900">配料信息</h3>
        <span class="text-xs text-slate-500">{{ parsedIngredients.length > 0 ? `${parsedIngredients.length} 项` : '加载中' }}</span>
      </div>
      
      <div v-if="parsedIngredients.length === 0" class="rounded-xl border border-dashed border-slate-300 bg-amber-50/50 px-4 py-6 text-sm text-slate-600">
        <p>详细配料分析生成中，请稍候...</p>
        <div class="mt-2 h-1 w-full overflow-hidden rounded-full bg-slate-200">
          <div class="h-full w-1/3 animate-pulse bg-amber-400"></div>
        </div>
      </div>
      
      <div v-else class="space-y-2.5 max-h-[800px] overflow-y-auto">
        <div
          v-for="(ingredient, idx) in parsedIngredients"
          :key="idx"
          class="group rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-3 transition-all hover:border-slate-300 hover:shadow-sm"
        >
          <!-- Header: name + safety indicator -->
          <div class="flex items-start justify-between gap-2 mb-2.5">
            <h4 class="text-sm font-semibold text-slate-900 flex-1 leading-snug">{{ ingredient.name }}</h4>
            <div class="shrink-0 flex items-center gap-1 text-xs">
              <span v-if="ingredient.safety.includes('合规')" class="inline-flex items-center gap-0.5 px-2 py-1 rounded-full bg-emerald-50 text-emerald-700 font-medium">
                <UIcon name="i-lucide-check-circle" class="size-3" />
                合规
              </span>
              <span v-else-if="ingredient.safety.includes('⚠️')" class="inline-flex items-center gap-0.5 px-2 py-1 rounded-full bg-amber-50 text-amber-700 font-medium">
                <UIcon name="i-lucide-alert-circle" class="size-3" />
                注意
              </span>
            </div>
          </div>
          
          <!-- Details grid -->
          <div class="space-y-1.5 text-xs text-slate-600">
            <!-- Function -->
            <div class="flex gap-2">
              <span class="shrink-0 font-semibold text-slate-700">作用：</span>
              <span class="flex-1 leading-relaxed">{{ ingredient.function || '—' }}</span>
            </div>
            
            <!-- Safety -->
            <div class="flex gap-2">
              <span class="shrink-0 font-semibold text-slate-700">安全：</span>
              <span class="flex-1 leading-relaxed line-clamp-2">{{ ingredient.safety || '—' }}</span>
            </div>
            
            <!-- Reminder -->
            <div v-if="ingredient.reminder && ingredient.reminder !== '无特别提醒'" class="flex gap-2 pt-0.5">
              <span class="shrink-0 font-semibold text-amber-700">⚠️ 提醒：</span>
              <span class="flex-1 leading-relaxed text-amber-700">{{ ingredient.reminder }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.markdown-content :deep(h2) {
  font-size: 0.875rem;
  font-weight: 600;
  color: #0f172a;
  margin-top: 0.625rem;
  margin-bottom: 0.125rem;
}

.markdown-content :deep(h2:first-child) {
  margin-top: 0;
}

.markdown-content :deep(ul) {
  list-style: none;
  padding-left: 0;
  margin: 0;
}

.markdown-content :deep(li) {
  font-size: 0.8125rem;
  line-height: 1.5;
  color: #475569;
}

.markdown-content :deep(p) {
  margin: 0;
}

.markdown-content :deep(strong) {
  color: #1e293b;
}
</style>
