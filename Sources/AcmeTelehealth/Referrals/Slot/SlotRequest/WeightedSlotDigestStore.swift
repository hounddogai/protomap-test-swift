import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted slot digests by code.
    protocol WeightedSlotDigestStore {
        func find(_ code: String) -> WeightedSlotDigest?
        func save(_ item: WeightedSlotDigest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSlotDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSlotDigestStore: WeightedSlotDigestStore {
        var items: [String: WeightedSlotDigest]
        var order: [String]

        init(items: [String: WeightedSlotDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSlotDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSlotDigest) {
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

        func list() -> [WeightedSlotDigest] {
            var out: [WeightedSlotDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSlotDigestStore() -> any WeightedSlotDigestStore {
        return MemoryWeightedSlotDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSlotDigestStore: WeightedSlotDigestStore {
        var inner: MemoryWeightedSlotDigestStore
        var cache: TTLCache<WeightedSlotDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSlotDigestStore, cache: TTLCache<WeightedSlotDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSlotDigest? {
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

        func save(_ item: WeightedSlotDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSlotDigest] {
            return inner.list()
        }
    }

    static func newCachedWeightedSlotDigestStore(_ inner: MemoryWeightedSlotDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSlotDigestStore {
        return CachedWeightedSlotDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted slot digests. Empty fields match all.
    final class WeightedSlotDigestQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSlotDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSlotDigest]) -> [WeightedSlotDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSlotDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSlotDigests(_ store: any WeightedSlotDigestStore, query: WeightedSlotDigestQuery) -> [WeightedSlotDigest] {
        return query.apply(store.list())
    }
}
