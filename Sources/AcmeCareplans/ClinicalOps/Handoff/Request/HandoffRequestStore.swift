import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff requests by code.
    protocol HandoffRequestStore {
        func find(_ code: String) -> HandoffRequest?
        func save(_ item: HandoffRequest)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffRequestStore: HandoffRequestStore {
        var items: [String: HandoffRequest]
        var order: [String]

        init(items: [String: HandoffRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffRequest) {
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

        func list() -> [HandoffRequest] {
            var out: [HandoffRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffRequestStore() -> any HandoffRequestStore {
        return MemoryHandoffRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffRequestStore: HandoffRequestStore {
        var inner: MemoryHandoffRequestStore
        var cache: TTLCache<HandoffRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffRequestStore, cache: TTLCache<HandoffRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffRequest? {
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

        func save(_ item: HandoffRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffRequest] {
            return inner.list()
        }
    }

    static func newCachedHandoffRequestStore(_ inner: MemoryHandoffRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffRequestStore {
        return CachedHandoffRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff requests. Empty fields match all.
    final class HandoffRequestQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffRequest]) -> [HandoffRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffRequests(_ store: any HandoffRequestStore, query: HandoffRequestQuery) -> [HandoffRequest] {
        return query.apply(store.list())
    }
}
