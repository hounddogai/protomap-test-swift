import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation claims by code.
    protocol IsolationClaimStore {
        func find(_ code: String) -> IsolationClaim?
        func save(_ item: IsolationClaim)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationClaimStore: IsolationClaimStore {
        var items: [String: IsolationClaim]
        var order: [String]

        init(items: [String: IsolationClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationClaim) {
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

        func list() -> [IsolationClaim] {
            var out: [IsolationClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationClaimStore() -> any IsolationClaimStore {
        return MemoryIsolationClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationClaimStore: IsolationClaimStore {
        var inner: MemoryIsolationClaimStore
        var cache: TTLCache<IsolationClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationClaimStore, cache: TTLCache<IsolationClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationClaim? {
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

        func save(_ item: IsolationClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationClaim] {
            return inner.list()
        }
    }

    static func newCachedIsolationClaimStore(_ inner: MemoryIsolationClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationClaimStore {
        return CachedIsolationClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation claims. Empty fields match all.
    final class IsolationClaimQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationClaim) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationClaim]) -> [IsolationClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationClaims(_ store: any IsolationClaimStore, query: IsolationClaimQuery) -> [IsolationClaim] {
        return query.apply(store.list())
    }
}
