import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert mappings by code.
    protocol AlertMappingStore {
        func find(_ code: String) -> AlertMapping?
        func save(_ item: AlertMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AlertMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertMappingStore: AlertMappingStore {
        var items: [String: AlertMapping]
        var order: [String]

        init(items: [String: AlertMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertMapping) {
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

        func list() -> [AlertMapping] {
            var out: [AlertMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertMappingStore() -> any AlertMappingStore {
        return MemoryAlertMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertMappingStore: AlertMappingStore {
        var inner: MemoryAlertMappingStore
        var cache: TTLCache<AlertMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertMappingStore, cache: TTLCache<AlertMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertMapping? {
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

        func save(_ item: AlertMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertMapping] {
            return inner.list()
        }
    }

    static func newCachedAlertMappingStore(_ inner: MemoryAlertMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertMappingStore {
        return CachedAlertMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert mappings. Empty fields match all.
    final class AlertMappingQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertMapping]) -> [AlertMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertMappings(_ store: any AlertMappingStore, query: AlertMappingQuery) -> [AlertMapping] {
        return query.apply(store.list())
    }
}
