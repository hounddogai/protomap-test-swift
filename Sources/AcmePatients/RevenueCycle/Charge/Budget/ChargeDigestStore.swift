import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge digests by code.
    protocol ChargeDigestStore {
        func find(_ code: String) -> ChargeDigest?
        func save(_ item: ChargeDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeDigestStore: ChargeDigestStore {
        var items: [String: ChargeDigest]
        var order: [String]

        init(items: [String: ChargeDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeDigest) {
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

        func list() -> [ChargeDigest] {
            var out: [ChargeDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeDigestStore() -> any ChargeDigestStore {
        return MemoryChargeDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeDigestStore: ChargeDigestStore {
        var inner: MemoryChargeDigestStore
        var cache: TTLCache<ChargeDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeDigestStore, cache: TTLCache<ChargeDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeDigest? {
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

        func save(_ item: ChargeDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeDigest] {
            return inner.list()
        }
    }

    static func newCachedChargeDigestStore(_ inner: MemoryChargeDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeDigestStore {
        return CachedChargeDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge digests. Empty fields match all.
    final class ChargeDigestQuery {
        var source: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeDigest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeDigest]) -> [ChargeDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeDigests(_ store: any ChargeDigestStore, query: ChargeDigestQuery) -> [ChargeDigest] {
        return query.apply(store.list())
    }
}
