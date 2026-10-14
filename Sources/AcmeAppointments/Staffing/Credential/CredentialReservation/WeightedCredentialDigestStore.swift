import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted credential digests by code.
    protocol WeightedCredentialDigestStore {
        func find(_ code: String) -> WeightedCredentialDigest?
        func save(_ item: WeightedCredentialDigest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCredentialDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCredentialDigestStore: WeightedCredentialDigestStore {
        var items: [String: WeightedCredentialDigest]
        var order: [String]

        init(items: [String: WeightedCredentialDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCredentialDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCredentialDigest) {
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

        func list() -> [WeightedCredentialDigest] {
            var out: [WeightedCredentialDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCredentialDigestStore() -> any WeightedCredentialDigestStore {
        return MemoryWeightedCredentialDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCredentialDigestStore: WeightedCredentialDigestStore {
        var inner: MemoryWeightedCredentialDigestStore
        var cache: TTLCache<WeightedCredentialDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCredentialDigestStore, cache: TTLCache<WeightedCredentialDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCredentialDigest? {
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

        func save(_ item: WeightedCredentialDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCredentialDigest] {
            return inner.list()
        }
    }

    static func newCachedWeightedCredentialDigestStore(_ inner: MemoryWeightedCredentialDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCredentialDigestStore {
        return CachedWeightedCredentialDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted credential digests. Empty fields match all.
    final class WeightedCredentialDigestQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCredentialDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCredentialDigest]) -> [WeightedCredentialDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCredentialDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCredentialDigests(_ store: any WeightedCredentialDigestStore, query: WeightedCredentialDigestQuery) -> [WeightedCredentialDigest] {
        return query.apply(store.list())
    }
}
