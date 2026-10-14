import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding groups by code.
    protocol RoundingGroupStore {
        func find(_ code: String) -> RoundingGroup?
        func save(_ item: RoundingGroup)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingGroupStore: RoundingGroupStore {
        var items: [String: RoundingGroup]
        var order: [String]

        init(items: [String: RoundingGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingGroup) {
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

        func list() -> [RoundingGroup] {
            var out: [RoundingGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingGroupStore() -> any RoundingGroupStore {
        return MemoryRoundingGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingGroupStore: RoundingGroupStore {
        var inner: MemoryRoundingGroupStore
        var cache: TTLCache<RoundingGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingGroupStore, cache: TTLCache<RoundingGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingGroup? {
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

        func save(_ item: RoundingGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingGroup] {
            return inner.list()
        }
    }

    static func newCachedRoundingGroupStore(_ inner: MemoryRoundingGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingGroupStore {
        return CachedRoundingGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding groups. Empty fields match all.
    final class RoundingGroupQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingGroup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingGroup]) -> [RoundingGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingGroups(_ store: any RoundingGroupStore, query: RoundingGroupQuery) -> [RoundingGroup] {
        return query.apply(store.list())
    }
}
