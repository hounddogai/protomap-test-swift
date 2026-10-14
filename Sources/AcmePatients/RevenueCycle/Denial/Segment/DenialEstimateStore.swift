import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial estimates by code.
    protocol DenialEstimateStore {
        func find(_ code: String) -> DenialEstimate?
        func save(_ item: DenialEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [DenialEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialEstimateStore: DenialEstimateStore {
        var items: [String: DenialEstimate]
        var order: [String]

        init(items: [String: DenialEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialEstimate) {
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

        func list() -> [DenialEstimate] {
            var out: [DenialEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialEstimateStore() -> any DenialEstimateStore {
        return MemoryDenialEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialEstimateStore: DenialEstimateStore {
        var inner: MemoryDenialEstimateStore
        var cache: TTLCache<DenialEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialEstimateStore, cache: TTLCache<DenialEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialEstimate? {
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

        func save(_ item: DenialEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialEstimate] {
            return inner.list()
        }
    }

    static func newCachedDenialEstimateStore(_ inner: MemoryDenialEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialEstimateStore {
        return CachedDenialEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial estimates. Empty fields match all.
    final class DenialEstimateQuery {
        var segment: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVersion: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialEstimate]) -> [DenialEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialEstimates(_ store: any DenialEstimateStore, query: DenialEstimateQuery) -> [DenialEstimate] {
        return query.apply(store.list())
    }
}
