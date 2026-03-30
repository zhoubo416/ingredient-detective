export interface TimingMeta {
  [key: string]: number | string | boolean | null | undefined
}

export interface TimingEntry {
  ms: number
  meta?: TimingMeta
}

export type TimingMap = Record<string, TimingEntry>

export function recordTiming(
  target: TimingMap,
  step: string,
  ms: number,
  meta?: TimingMeta
) {
  target[step] = {
    ms,
    ...(meta ? { meta } : {})
  }
}

export async function measureTiming<T>(
  target: TimingMap,
  step: string,
  action: () => Promise<T>,
  meta?: TimingMeta
) {
  const startedAt = Date.now()
  const result = await action()
  recordTiming(target, step, Date.now() - startedAt, meta)
  return result
}

export function flattenTimingMap(timings: TimingMap) {
  return Object.fromEntries(
    Object.entries(timings).map(([step, entry]) => [step, entry.ms])
  )
}
