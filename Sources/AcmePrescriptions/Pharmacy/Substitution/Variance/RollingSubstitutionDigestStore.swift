import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling substitution digests by code.
    protocol RollingSubstitutionDigestStore {
        func find(_ code: String) -> RollingSubstitutionDigest?
        func save(_ item: RollingSubstitutionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingSubstitutionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingSubstitutionDigestStore: RollingSubstitutionDigestStore {
        var items: [String: RollingSubstitutionDigest]
        var order: [String]

        init(items: [String: RollingSubstitutionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingSubstitutionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingSubstitutionDigest) {
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

        func list() -> [RollingSubstitutionDigest] {
            var out: [RollingSubstitutionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingSubstitutionDigestStore() -> any RollingSubstitutionDigestStore {
        return MemoryRollingSubstitutionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingSubstitutionDigestStore: RollingSubstitutionDigestStore {
        var inner: MemoryRollingSubstitutionDigestStore
        var cache: TTLCache<RollingSubstitutionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingSubstitutionDigestStore, cache: TTLCache<RollingSubstitutionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingSubstitutionDigest? {
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

        func save(_ item: RollingSubstitutionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingSubstitutionDigest] {
            return inner.list()
        }
    }

    static func newCachedRollingSubstitutionDigestStore(_ inner: MemoryRollingSubstitutionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingSubstitutionDigestStore {
        return CachedRollingSubstitutionDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling substitution digests. Empty fields match all.
    final class RollingSubstitutionDigestQuery {
        var ward: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minAmount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingSubstitutionDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingSubstitutionDigest]) -> [RollingSubstitutionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingSubstitutionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingSubstitutionDigests(_ store: any RollingSubstitutionDigestStore, query: RollingSubstitutionDigestQuery) -> [RollingSubstitutionDigest] {
        return query.apply(store.list())
    }
}
