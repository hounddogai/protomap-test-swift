import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive handoff requests by code.
    protocol AdaptiveHandoffRequestStore {
        func find(_ code: String) -> AdaptiveHandoffRequest?
        func save(_ item: AdaptiveHandoffRequest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveHandoffRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveHandoffRequestStore: AdaptiveHandoffRequestStore {
        var items: [String: AdaptiveHandoffRequest]
        var order: [String]

        init(items: [String: AdaptiveHandoffRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveHandoffRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveHandoffRequest) {
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

        func list() -> [AdaptiveHandoffRequest] {
            var out: [AdaptiveHandoffRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveHandoffRequestStore() -> any AdaptiveHandoffRequestStore {
        return MemoryAdaptiveHandoffRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveHandoffRequestStore: AdaptiveHandoffRequestStore {
        var inner: MemoryAdaptiveHandoffRequestStore
        var cache: TTLCache<AdaptiveHandoffRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveHandoffRequestStore, cache: TTLCache<AdaptiveHandoffRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveHandoffRequest? {
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

        func save(_ item: AdaptiveHandoffRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveHandoffRequest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveHandoffRequestStore(_ inner: MemoryAdaptiveHandoffRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveHandoffRequestStore {
        return CachedAdaptiveHandoffRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive handoff requests. Empty fields match all.
    final class AdaptiveHandoffRequestQuery {
        var channel: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveHandoffRequest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveHandoffRequest]) -> [AdaptiveHandoffRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveHandoffRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveHandoffRequests(_ store: any AdaptiveHandoffRequestStore, query: AdaptiveHandoffRequestQuery) -> [AdaptiveHandoffRequest] {
        return query.apply(store.list())
    }
}
