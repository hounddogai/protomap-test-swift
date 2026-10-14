import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual care protocol requests by code.
    protocol ManualCareProtocolRequestStore {
        func find(_ code: String) -> ManualCareProtocolRequest?
        func save(_ item: ManualCareProtocolRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolRequestStore: ManualCareProtocolRequestStore {
        var items: [String: ManualCareProtocolRequest]
        var order: [String]

        init(items: [String: ManualCareProtocolRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolRequest) {
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

        func list() -> [ManualCareProtocolRequest] {
            var out: [ManualCareProtocolRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolRequestStore() -> any ManualCareProtocolRequestStore {
        return MemoryManualCareProtocolRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolRequestStore: ManualCareProtocolRequestStore {
        var inner: MemoryManualCareProtocolRequestStore
        var cache: TTLCache<ManualCareProtocolRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolRequestStore, cache: TTLCache<ManualCareProtocolRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolRequest? {
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

        func save(_ item: ManualCareProtocolRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolRequest] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolRequestStore(_ inner: MemoryManualCareProtocolRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolRequestStore {
        return CachedManualCareProtocolRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol requests. Empty fields match all.
    final class ManualCareProtocolRequestQuery {
        var channel: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolRequest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ManualCareProtocolRequest]) -> [ManualCareProtocolRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolRequests(_ store: any ManualCareProtocolRequestStore, query: ManualCareProtocolRequestQuery) -> [ManualCareProtocolRequest] {
        return query.apply(store.list())
    }
}
