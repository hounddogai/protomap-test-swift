import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix mappings by code.
    protocol SkillMixMappingStore {
        func find(_ code: String) -> SkillMixMapping?
        func save(_ item: SkillMixMapping)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixMappingStore: SkillMixMappingStore {
        var items: [String: SkillMixMapping]
        var order: [String]

        init(items: [String: SkillMixMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixMapping) {
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

        func list() -> [SkillMixMapping] {
            var out: [SkillMixMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixMappingStore() -> any SkillMixMappingStore {
        return MemorySkillMixMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixMappingStore: SkillMixMappingStore {
        var inner: MemorySkillMixMappingStore
        var cache: TTLCache<SkillMixMapping>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixMappingStore, cache: TTLCache<SkillMixMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixMapping? {
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

        func save(_ item: SkillMixMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixMapping] {
            return inner.list()
        }
    }

    static func newCachedSkillMixMappingStore(_ inner: MemorySkillMixMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixMappingStore {
        return CachedSkillMixMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix mappings. Empty fields match all.
    final class SkillMixMappingQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixMapping) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixMapping]) -> [SkillMixMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixMappings(_ store: any SkillMixMappingStore, query: SkillMixMappingQuery) -> [SkillMixMapping] {
        return query.apply(store.list())
    }
}
