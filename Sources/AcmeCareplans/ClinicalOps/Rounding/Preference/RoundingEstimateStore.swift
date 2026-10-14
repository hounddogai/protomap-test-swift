import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding estimates by code.
    protocol RoundingEstimateStore {
        func find(_ code: String) -> RoundingEstimate?
        func save(_ item: RoundingEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingEstimateStore: RoundingEstimateStore {
        var items: [String: RoundingEstimate]
        var order: [String]

        init(items: [String: RoundingEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingEstimate) {
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

        func list() -> [RoundingEstimate] {
            var out: [RoundingEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingEstimateStore() -> any RoundingEstimateStore {
        return MemoryRoundingEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingEstimateStore: RoundingEstimateStore {
        var inner: MemoryRoundingEstimateStore
        var cache: TTLCache<RoundingEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingEstimateStore, cache: TTLCache<RoundingEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingEstimate? {
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

        func save(_ item: RoundingEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingEstimate] {
            return inner.list()
        }
    }

    static func newCachedRoundingEstimateStore(_ inner: MemoryRoundingEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingEstimateStore {
        return CachedRoundingEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding estimates. Empty fields match all.
    final class RoundingEstimateQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingEstimate]) -> [RoundingEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingEstimates(_ store: any RoundingEstimateStore, query: RoundingEstimateQuery) -> [RoundingEstimate] {
        return query.apply(store.list())
    }
}
