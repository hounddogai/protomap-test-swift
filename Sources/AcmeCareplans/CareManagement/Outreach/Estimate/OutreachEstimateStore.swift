import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach estimates by code.
    protocol OutreachEstimateStore {
        func find(_ code: String) -> OutreachEstimate?
        func save(_ item: OutreachEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachEstimateStore: OutreachEstimateStore {
        var items: [String: OutreachEstimate]
        var order: [String]

        init(items: [String: OutreachEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachEstimate) {
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

        func list() -> [OutreachEstimate] {
            var out: [OutreachEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachEstimateStore() -> any OutreachEstimateStore {
        return MemoryOutreachEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachEstimateStore: OutreachEstimateStore {
        var inner: MemoryOutreachEstimateStore
        var cache: TTLCache<OutreachEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachEstimateStore, cache: TTLCache<OutreachEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachEstimate? {
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

        func save(_ item: OutreachEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachEstimate] {
            return inner.list()
        }
    }

    static func newCachedOutreachEstimateStore(_ inner: MemoryOutreachEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachEstimateStore {
        return CachedOutreachEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach estimates. Empty fields match all.
    final class OutreachEstimateQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [OutreachEstimate]) -> [OutreachEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachEstimates(_ store: any OutreachEstimateStore, query: OutreachEstimateQuery) -> [OutreachEstimate] {
        return query.apply(store.list())
    }
}
