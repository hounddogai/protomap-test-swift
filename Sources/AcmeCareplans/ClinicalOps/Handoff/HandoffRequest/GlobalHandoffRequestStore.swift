import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global handoff requests by code.
    protocol GlobalHandoffRequestStore {
        func find(_ code: String) -> GlobalHandoffRequest?
        func save(_ item: GlobalHandoffRequest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalHandoffRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalHandoffRequestStore: GlobalHandoffRequestStore {
        var items: [String: GlobalHandoffRequest]
        var order: [String]

        init(items: [String: GlobalHandoffRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalHandoffRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalHandoffRequest) {
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

        func list() -> [GlobalHandoffRequest] {
            var out: [GlobalHandoffRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalHandoffRequestStore() -> any GlobalHandoffRequestStore {
        return MemoryGlobalHandoffRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalHandoffRequestStore: GlobalHandoffRequestStore {
        var inner: MemoryGlobalHandoffRequestStore
        var cache: TTLCache<GlobalHandoffRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalHandoffRequestStore, cache: TTLCache<GlobalHandoffRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalHandoffRequest? {
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

        func save(_ item: GlobalHandoffRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalHandoffRequest] {
            return inner.list()
        }
    }

    static func newCachedGlobalHandoffRequestStore(_ inner: MemoryGlobalHandoffRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalHandoffRequestStore {
        return CachedGlobalHandoffRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global handoff requests. Empty fields match all.
    final class GlobalHandoffRequestQuery {
        var category: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minBudget: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalHandoffRequest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [GlobalHandoffRequest]) -> [GlobalHandoffRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalHandoffRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalHandoffRequests(_ store: any GlobalHandoffRequestStore, query: GlobalHandoffRequestQuery) -> [GlobalHandoffRequest] {
        return query.apply(store.list())
    }
}
