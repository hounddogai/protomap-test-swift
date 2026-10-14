import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential variances by code.
    protocol CredentialVarianceStore {
        func find(_ code: String) -> CredentialVariance?
        func save(_ item: CredentialVariance)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialVarianceStore: CredentialVarianceStore {
        var items: [String: CredentialVariance]
        var order: [String]

        init(items: [String: CredentialVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialVariance) {
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

        func list() -> [CredentialVariance] {
            var out: [CredentialVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialVarianceStore() -> any CredentialVarianceStore {
        return MemoryCredentialVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialVarianceStore: CredentialVarianceStore {
        var inner: MemoryCredentialVarianceStore
        var cache: TTLCache<CredentialVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialVarianceStore, cache: TTLCache<CredentialVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialVariance? {
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

        func save(_ item: CredentialVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialVariance] {
            return inner.list()
        }
    }

    static func newCachedCredentialVarianceStore(_ inner: MemoryCredentialVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialVarianceStore {
        return CachedCredentialVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential variances. Empty fields match all.
    final class CredentialVarianceQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [CredentialVariance]) -> [CredentialVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialVariances(_ store: any CredentialVarianceStore, query: CredentialVarianceQuery) -> [CredentialVariance] {
        return query.apply(store.list())
    }
}
