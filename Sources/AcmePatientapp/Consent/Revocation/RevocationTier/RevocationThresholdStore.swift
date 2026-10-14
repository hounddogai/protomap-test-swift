import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation thresholds by code.
    protocol RevocationThresholdStore {
        func find(_ code: String) -> RevocationThreshold?
        func save(_ item: RevocationThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationThresholdStore: RevocationThresholdStore {
        var items: [String: RevocationThreshold]
        var order: [String]

        init(items: [String: RevocationThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationThreshold) {
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

        func list() -> [RevocationThreshold] {
            var out: [RevocationThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationThresholdStore() -> any RevocationThresholdStore {
        return MemoryRevocationThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationThresholdStore: RevocationThresholdStore {
        var inner: MemoryRevocationThresholdStore
        var cache: TTLCache<RevocationThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationThresholdStore, cache: TTLCache<RevocationThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationThreshold? {
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

        func save(_ item: RevocationThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationThreshold] {
            return inner.list()
        }
    }

    static func newCachedRevocationThresholdStore(_ inner: MemoryRevocationThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationThresholdStore {
        return CachedRevocationThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation thresholds. Empty fields match all.
    final class RevocationThresholdQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationThreshold) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationThreshold]) -> [RevocationThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationThresholds(_ store: any RevocationThresholdStore, query: RevocationThresholdQuery) -> [RevocationThreshold] {
        return query.apply(store.list())
    }
}
