import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix batches by code.
    protocol SkillMixBatchStore {
        func find(_ code: String) -> SkillMixBatch?
        func save(_ item: SkillMixBatch)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixBatchStore: SkillMixBatchStore {
        var items: [String: SkillMixBatch]
        var order: [String]

        init(items: [String: SkillMixBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixBatch) {
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

        func list() -> [SkillMixBatch] {
            var out: [SkillMixBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixBatchStore() -> any SkillMixBatchStore {
        return MemorySkillMixBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixBatchStore: SkillMixBatchStore {
        var inner: MemorySkillMixBatchStore
        var cache: TTLCache<SkillMixBatch>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixBatchStore, cache: TTLCache<SkillMixBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixBatch? {
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

        func save(_ item: SkillMixBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixBatch] {
            return inner.list()
        }
    }

    static func newCachedSkillMixBatchStore(_ inner: MemorySkillMixBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixBatchStore {
        return CachedSkillMixBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix batches. Empty fields match all.
    final class SkillMixBatchQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixBatch) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixBatch]) -> [SkillMixBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixBatches(_ store: any SkillMixBatchStore, query: SkillMixBatchQuery) -> [SkillMixBatch] {
        return query.apply(store.list())
    }
}
