import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol estimates by code.
    protocol CareProtocolEstimateStore {
        func find(_ code: String) -> CareProtocolEstimate?
        func save(_ item: CareProtocolEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolEstimateStore: CareProtocolEstimateStore {
        var items: [String: CareProtocolEstimate]
        var order: [String]

        init(items: [String: CareProtocolEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolEstimate) {
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

        func list() -> [CareProtocolEstimate] {
            var out: [CareProtocolEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolEstimateStore() -> any CareProtocolEstimateStore {
        return MemoryCareProtocolEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolEstimateStore: CareProtocolEstimateStore {
        var inner: MemoryCareProtocolEstimateStore
        var cache: TTLCache<CareProtocolEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolEstimateStore, cache: TTLCache<CareProtocolEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolEstimate? {
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

        func save(_ item: CareProtocolEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolEstimate] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolEstimateStore(_ inner: MemoryCareProtocolEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolEstimateStore {
        return CachedCareProtocolEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol estimates. Empty fields match all.
    final class CareProtocolEstimateQuery {
        var channel: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolEstimate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolEstimate]) -> [CareProtocolEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolEstimates(_ store: any CareProtocolEstimateStore, query: CareProtocolEstimateQuery) -> [CareProtocolEstimate] {
        return query.apply(store.list())
    }
}
