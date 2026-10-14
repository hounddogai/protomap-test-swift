import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set manifests by code.
    protocol OrderSetManifestStore {
        func find(_ code: String) -> OrderSetManifest?
        func save(_ item: OrderSetManifest)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetManifestStore: OrderSetManifestStore {
        var items: [String: OrderSetManifest]
        var order: [String]

        init(items: [String: OrderSetManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetManifest) {
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

        func list() -> [OrderSetManifest] {
            var out: [OrderSetManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetManifestStore() -> any OrderSetManifestStore {
        return MemoryOrderSetManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetManifestStore: OrderSetManifestStore {
        var inner: MemoryOrderSetManifestStore
        var cache: TTLCache<OrderSetManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetManifestStore, cache: TTLCache<OrderSetManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetManifest? {
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

        func save(_ item: OrderSetManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetManifest] {
            return inner.list()
        }
    }

    static func newCachedOrderSetManifestStore(_ inner: MemoryOrderSetManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetManifestStore {
        return CachedOrderSetManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set manifests. Empty fields match all.
    final class OrderSetManifestQuery {
        var segment: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetManifest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetManifest]) -> [OrderSetManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetManifests(_ store: any OrderSetManifestStore, query: OrderSetManifestQuery) -> [OrderSetManifest] {
        return query.apply(store.list())
    }
}
