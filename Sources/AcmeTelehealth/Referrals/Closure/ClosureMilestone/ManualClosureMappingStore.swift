import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual closure mappings by code.
    protocol ManualClosureMappingStore {
        func find(_ code: String) -> ManualClosureMapping?
        func save(_ item: ManualClosureMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ManualClosureMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualClosureMappingStore: ManualClosureMappingStore {
        var items: [String: ManualClosureMapping]
        var order: [String]

        init(items: [String: ManualClosureMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualClosureMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualClosureMapping) {
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

        func list() -> [ManualClosureMapping] {
            var out: [ManualClosureMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualClosureMappingStore() -> any ManualClosureMappingStore {
        return MemoryManualClosureMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualClosureMappingStore: ManualClosureMappingStore {
        var inner: MemoryManualClosureMappingStore
        var cache: TTLCache<ManualClosureMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualClosureMappingStore, cache: TTLCache<ManualClosureMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualClosureMapping? {
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

        func save(_ item: ManualClosureMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualClosureMapping] {
            return inner.list()
        }
    }

    static func newCachedManualClosureMappingStore(_ inner: MemoryManualClosureMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualClosureMappingStore {
        return CachedManualClosureMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual closure mappings. Empty fields match all.
    final class ManualClosureMappingQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualClosureMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualClosureMapping]) -> [ManualClosureMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualClosureMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualClosureMappings(_ store: any ManualClosureMappingStore, query: ManualClosureMappingQuery) -> [ManualClosureMapping] {
        return query.apply(store.list())
    }
}
