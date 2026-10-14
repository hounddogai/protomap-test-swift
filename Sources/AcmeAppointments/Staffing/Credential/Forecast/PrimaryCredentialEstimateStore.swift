import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary credential estimates by code.
    protocol PrimaryCredentialEstimateStore {
        func find(_ code: String) -> PrimaryCredentialEstimate?
        func save(_ item: PrimaryCredentialEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCredentialEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCredentialEstimateStore: PrimaryCredentialEstimateStore {
        var items: [String: PrimaryCredentialEstimate]
        var order: [String]

        init(items: [String: PrimaryCredentialEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCredentialEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCredentialEstimate) {
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

        func list() -> [PrimaryCredentialEstimate] {
            var out: [PrimaryCredentialEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCredentialEstimateStore() -> any PrimaryCredentialEstimateStore {
        return MemoryPrimaryCredentialEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCredentialEstimateStore: PrimaryCredentialEstimateStore {
        var inner: MemoryPrimaryCredentialEstimateStore
        var cache: TTLCache<PrimaryCredentialEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCredentialEstimateStore, cache: TTLCache<PrimaryCredentialEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCredentialEstimate? {
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

        func save(_ item: PrimaryCredentialEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCredentialEstimate] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCredentialEstimateStore(_ inner: MemoryPrimaryCredentialEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCredentialEstimateStore {
        return CachedPrimaryCredentialEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary credential estimates. Empty fields match all.
    final class PrimaryCredentialEstimateQuery {
        var unit: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRate: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCredentialEstimate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCredentialEstimate]) -> [PrimaryCredentialEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCredentialEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCredentialEstimates(_ store: any PrimaryCredentialEstimateStore, query: PrimaryCredentialEstimateQuery) -> [PrimaryCredentialEstimate] {
        return query.apply(store.list())
    }
}
