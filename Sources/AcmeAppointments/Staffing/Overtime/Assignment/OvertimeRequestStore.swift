import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime requests by code.
    protocol OvertimeRequestStore {
        func find(_ code: String) -> OvertimeRequest?
        func save(_ item: OvertimeRequest)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeRequestStore: OvertimeRequestStore {
        var items: [String: OvertimeRequest]
        var order: [String]

        init(items: [String: OvertimeRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeRequest) {
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

        func list() -> [OvertimeRequest] {
            var out: [OvertimeRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeRequestStore() -> any OvertimeRequestStore {
        return MemoryOvertimeRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeRequestStore: OvertimeRequestStore {
        var inner: MemoryOvertimeRequestStore
        var cache: TTLCache<OvertimeRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeRequestStore, cache: TTLCache<OvertimeRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeRequest? {
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

        func save(_ item: OvertimeRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeRequest] {
            return inner.list()
        }
    }

    static func newCachedOvertimeRequestStore(_ inner: MemoryOvertimeRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeRequestStore {
        return CachedOvertimeRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime requests. Empty fields match all.
    final class OvertimeRequestQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [OvertimeRequest]) -> [OvertimeRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeRequests(_ store: any OvertimeRequestStore, query: OvertimeRequestQuery) -> [OvertimeRequest] {
        return query.apply(store.list())
    }
}
