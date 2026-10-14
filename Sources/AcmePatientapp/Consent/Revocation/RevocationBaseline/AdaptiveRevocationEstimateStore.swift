import AcmePlatform
import Foundation

extension Consent {
    /// Keeps adaptive revocation estimates by code.
    protocol AdaptiveRevocationEstimateStore {
        func find(_ code: String) -> AdaptiveRevocationEstimate?
        func save(_ item: AdaptiveRevocationEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRevocationEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRevocationEstimateStore: AdaptiveRevocationEstimateStore {
        var items: [String: AdaptiveRevocationEstimate]
        var order: [String]

        init(items: [String: AdaptiveRevocationEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRevocationEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRevocationEstimate) {
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

        func list() -> [AdaptiveRevocationEstimate] {
            var out: [AdaptiveRevocationEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRevocationEstimateStore() -> any AdaptiveRevocationEstimateStore {
        return MemoryAdaptiveRevocationEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRevocationEstimateStore: AdaptiveRevocationEstimateStore {
        var inner: MemoryAdaptiveRevocationEstimateStore
        var cache: TTLCache<AdaptiveRevocationEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRevocationEstimateStore, cache: TTLCache<AdaptiveRevocationEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRevocationEstimate? {
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

        func save(_ item: AdaptiveRevocationEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRevocationEstimate] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRevocationEstimateStore(_ inner: MemoryAdaptiveRevocationEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRevocationEstimateStore {
        return CachedAdaptiveRevocationEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive revocation estimates. Empty fields match all.
    final class AdaptiveRevocationEstimateQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRevocationEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRevocationEstimate]) -> [AdaptiveRevocationEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRevocationEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRevocationEstimates(_ store: any AdaptiveRevocationEstimateStore, query: AdaptiveRevocationEstimateQuery) -> [AdaptiveRevocationEstimate] {
        return query.apply(store.list())
    }
}
