import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual credential mappings by code.
    protocol ManualCredentialMappingStore {
        func find(_ code: String) -> ManualCredentialMapping?
        func save(_ item: ManualCredentialMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCredentialMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCredentialMappingStore: ManualCredentialMappingStore {
        var items: [String: ManualCredentialMapping]
        var order: [String]

        init(items: [String: ManualCredentialMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCredentialMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCredentialMapping) {
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

        func list() -> [ManualCredentialMapping] {
            var out: [ManualCredentialMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCredentialMappingStore() -> any ManualCredentialMappingStore {
        return MemoryManualCredentialMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCredentialMappingStore: ManualCredentialMappingStore {
        var inner: MemoryManualCredentialMappingStore
        var cache: TTLCache<ManualCredentialMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCredentialMappingStore, cache: TTLCache<ManualCredentialMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCredentialMapping? {
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

        func save(_ item: ManualCredentialMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCredentialMapping] {
            return inner.list()
        }
    }

    static func newCachedManualCredentialMappingStore(_ inner: MemoryManualCredentialMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCredentialMappingStore {
        return CachedManualCredentialMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual credential mappings. Empty fields match all.
    final class ManualCredentialMappingQuery {
        var source: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCredentialMapping) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ManualCredentialMapping]) -> [ManualCredentialMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCredentialMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCredentialMappings(_ store: any ManualCredentialMappingStore, query: ManualCredentialMappingQuery) -> [ManualCredentialMapping] {
        return query.apply(store.list())
    }
}
