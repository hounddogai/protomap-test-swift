import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted interaction digests by code.
    protocol WeightedInteractionDigestStore {
        func find(_ code: String) -> WeightedInteractionDigest?
        func save(_ item: WeightedInteractionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedInteractionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedInteractionDigestStore: WeightedInteractionDigestStore {
        var items: [String: WeightedInteractionDigest]
        var order: [String]

        init(items: [String: WeightedInteractionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedInteractionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedInteractionDigest) {
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

        func list() -> [WeightedInteractionDigest] {
            var out: [WeightedInteractionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedInteractionDigestStore() -> any WeightedInteractionDigestStore {
        return MemoryWeightedInteractionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedInteractionDigestStore: WeightedInteractionDigestStore {
        var inner: MemoryWeightedInteractionDigestStore
        var cache: TTLCache<WeightedInteractionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedInteractionDigestStore, cache: TTLCache<WeightedInteractionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedInteractionDigest? {
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

        func save(_ item: WeightedInteractionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedInteractionDigest] {
            return inner.list()
        }
    }

    static func newCachedWeightedInteractionDigestStore(_ inner: MemoryWeightedInteractionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedInteractionDigestStore {
        return CachedWeightedInteractionDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted interaction digests. Empty fields match all.
    final class WeightedInteractionDigestQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedInteractionDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [WeightedInteractionDigest]) -> [WeightedInteractionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedInteractionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedInteractionDigests(_ store: any WeightedInteractionDigestStore, query: WeightedInteractionDigestQuery) -> [WeightedInteractionDigest] {
        return query.apply(store.list())
    }
}
