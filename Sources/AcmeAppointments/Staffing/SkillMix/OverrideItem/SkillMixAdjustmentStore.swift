import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix adjustments by code.
    protocol SkillMixAdjustmentStore {
        func find(_ code: String) -> SkillMixAdjustment?
        func save(_ item: SkillMixAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixAdjustmentStore: SkillMixAdjustmentStore {
        var items: [String: SkillMixAdjustment]
        var order: [String]

        init(items: [String: SkillMixAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixAdjustment) {
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

        func list() -> [SkillMixAdjustment] {
            var out: [SkillMixAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixAdjustmentStore() -> any SkillMixAdjustmentStore {
        return MemorySkillMixAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixAdjustmentStore: SkillMixAdjustmentStore {
        var inner: MemorySkillMixAdjustmentStore
        var cache: TTLCache<SkillMixAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixAdjustmentStore, cache: TTLCache<SkillMixAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixAdjustment? {
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

        func save(_ item: SkillMixAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixAdjustment] {
            return inner.list()
        }
    }

    static func newCachedSkillMixAdjustmentStore(_ inner: MemorySkillMixAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixAdjustmentStore {
        return CachedSkillMixAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix adjustments. Empty fields match all.
    final class SkillMixAdjustmentQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixAdjustment]) -> [SkillMixAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixAdjustments(_ store: any SkillMixAdjustmentStore, query: SkillMixAdjustmentQuery) -> [SkillMixAdjustment] {
        return query.apply(store.list())
    }
}
