import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default remittance digests by code.
    protocol DefaultRemittanceDigestStore {
        func find(_ code: String) -> DefaultRemittanceDigest?
        func save(_ item: DefaultRemittanceDigest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRemittanceDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRemittanceDigestStore: DefaultRemittanceDigestStore {
        var items: [String: DefaultRemittanceDigest]
        var order: [String]

        init(items: [String: DefaultRemittanceDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRemittanceDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRemittanceDigest) {
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

        func list() -> [DefaultRemittanceDigest] {
            var out: [DefaultRemittanceDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRemittanceDigestStore() -> any DefaultRemittanceDigestStore {
        return MemoryDefaultRemittanceDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRemittanceDigestStore: DefaultRemittanceDigestStore {
        var inner: MemoryDefaultRemittanceDigestStore
        var cache: TTLCache<DefaultRemittanceDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRemittanceDigestStore, cache: TTLCache<DefaultRemittanceDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRemittanceDigest? {
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

        func save(_ item: DefaultRemittanceDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRemittanceDigest] {
            return inner.list()
        }
    }

    static func newCachedDefaultRemittanceDigestStore(_ inner: MemoryDefaultRemittanceDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRemittanceDigestStore {
        return CachedDefaultRemittanceDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default remittance digests. Empty fields match all.
    final class DefaultRemittanceDigestQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRemittanceDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [DefaultRemittanceDigest]) -> [DefaultRemittanceDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRemittanceDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRemittanceDigests(_ store: any DefaultRemittanceDigestStore, query: DefaultRemittanceDigestQuery) -> [DefaultRemittanceDigest] {
        return query.apply(store.list())
    }
}
