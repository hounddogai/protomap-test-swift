import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global slot estimates by code.
    protocol GlobalSlotEstimateStore {
        func find(_ code: String) -> GlobalSlotEstimate?
        func save(_ item: GlobalSlotEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSlotEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSlotEstimateStore: GlobalSlotEstimateStore {
        var items: [String: GlobalSlotEstimate]
        var order: [String]

        init(items: [String: GlobalSlotEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSlotEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSlotEstimate) {
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

        func list() -> [GlobalSlotEstimate] {
            var out: [GlobalSlotEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSlotEstimateStore() -> any GlobalSlotEstimateStore {
        return MemoryGlobalSlotEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSlotEstimateStore: GlobalSlotEstimateStore {
        var inner: MemoryGlobalSlotEstimateStore
        var cache: TTLCache<GlobalSlotEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSlotEstimateStore, cache: TTLCache<GlobalSlotEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSlotEstimate? {
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

        func save(_ item: GlobalSlotEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSlotEstimate] {
            return inner.list()
        }
    }

    static func newCachedGlobalSlotEstimateStore(_ inner: MemoryGlobalSlotEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSlotEstimateStore {
        return CachedGlobalSlotEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global slot estimates. Empty fields match all.
    final class GlobalSlotEstimateQuery {
        var channel: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMargin: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSlotEstimate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSlotEstimate]) -> [GlobalSlotEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSlotEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSlotEstimates(_ store: any GlobalSlotEstimateStore, query: GlobalSlotEstimateQuery) -> [GlobalSlotEstimate] {
        return query.apply(store.list())
    }
}
