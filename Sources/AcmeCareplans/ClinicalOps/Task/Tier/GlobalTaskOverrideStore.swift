import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global task overrides by code.
    protocol GlobalTaskOverrideStore {
        func find(_ code: String) -> GlobalTaskOverride?
        func save(_ item: GlobalTaskOverride)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalTaskOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalTaskOverrideStore: GlobalTaskOverrideStore {
        var items: [String: GlobalTaskOverride]
        var order: [String]

        init(items: [String: GlobalTaskOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalTaskOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalTaskOverride) {
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

        func list() -> [GlobalTaskOverride] {
            var out: [GlobalTaskOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalTaskOverrideStore() -> any GlobalTaskOverrideStore {
        return MemoryGlobalTaskOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalTaskOverrideStore: GlobalTaskOverrideStore {
        var inner: MemoryGlobalTaskOverrideStore
        var cache: TTLCache<GlobalTaskOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalTaskOverrideStore, cache: TTLCache<GlobalTaskOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalTaskOverride? {
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

        func save(_ item: GlobalTaskOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalTaskOverride] {
            return inner.list()
        }
    }

    static func newCachedGlobalTaskOverrideStore(_ inner: MemoryGlobalTaskOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalTaskOverrideStore {
        return CachedGlobalTaskOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global task overrides. Empty fields match all.
    final class GlobalTaskOverrideQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalTaskOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalTaskOverride]) -> [GlobalTaskOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalTaskOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalTaskOverrides(_ store: any GlobalTaskOverrideStore, query: GlobalTaskOverrideQuery) -> [GlobalTaskOverride] {
        return query.apply(store.list())
    }
}
