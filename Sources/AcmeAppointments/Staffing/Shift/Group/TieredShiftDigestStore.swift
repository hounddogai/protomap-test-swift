import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered shift digests by code.
    protocol TieredShiftDigestStore {
        func find(_ code: String) -> TieredShiftDigest?
        func save(_ item: TieredShiftDigest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredShiftDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredShiftDigestStore: TieredShiftDigestStore {
        var items: [String: TieredShiftDigest]
        var order: [String]

        init(items: [String: TieredShiftDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredShiftDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredShiftDigest) {
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

        func list() -> [TieredShiftDigest] {
            var out: [TieredShiftDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredShiftDigestStore() -> any TieredShiftDigestStore {
        return MemoryTieredShiftDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredShiftDigestStore: TieredShiftDigestStore {
        var inner: MemoryTieredShiftDigestStore
        var cache: TTLCache<TieredShiftDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredShiftDigestStore, cache: TTLCache<TieredShiftDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredShiftDigest? {
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

        func save(_ item: TieredShiftDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredShiftDigest] {
            return inner.list()
        }
    }

    static func newCachedTieredShiftDigestStore(_ inner: MemoryTieredShiftDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredShiftDigestStore {
        return CachedTieredShiftDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered shift digests. Empty fields match all.
    final class TieredShiftDigestQuery {
        var category: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredShiftDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [TieredShiftDigest]) -> [TieredShiftDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredShiftDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredShiftDigests(_ store: any TieredShiftDigestStore, query: TieredShiftDigestQuery) -> [TieredShiftDigest] {
        return query.apply(store.list())
    }
}
