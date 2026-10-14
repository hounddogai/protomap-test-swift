import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped skill mix cycles by code.
    protocol CappedSkillMixCycleStore {
        func find(_ code: String) -> CappedSkillMixCycle?
        func save(_ item: CappedSkillMixCycle)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSkillMixCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSkillMixCycleStore: CappedSkillMixCycleStore {
        var items: [String: CappedSkillMixCycle]
        var order: [String]

        init(items: [String: CappedSkillMixCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSkillMixCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSkillMixCycle) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [CappedSkillMixCycle] {
            var out: [CappedSkillMixCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSkillMixCycleStore() -> any CappedSkillMixCycleStore {
        return MemoryCappedSkillMixCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSkillMixCycleStore: CappedSkillMixCycleStore {
        var inner: MemoryCappedSkillMixCycleStore
        var cache: TTLCache<CappedSkillMixCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSkillMixCycleStore, cache: TTLCache<CappedSkillMixCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSkillMixCycle? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: CappedSkillMixCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSkillMixCycle] {
            return inner.list()
        }
    }

    static func newCachedCappedSkillMixCycleStore(_ inner: MemoryCappedSkillMixCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSkillMixCycleStore {
        return CachedCappedSkillMixCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped skill mix cycles. Empty fields match all.
    final class CappedSkillMixCycleQuery {
        var unit: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSkillMixCycle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedSkillMixCycle]) -> [CappedSkillMixCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSkillMixCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSkillMixCycles(_ store: any CappedSkillMixCycleStore, query: CappedSkillMixCycleQuery) -> [CappedSkillMixCycle] {
        return query.apply(store.list())
    }
}
