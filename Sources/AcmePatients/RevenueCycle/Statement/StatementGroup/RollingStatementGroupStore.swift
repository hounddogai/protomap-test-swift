import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling statement groups by code.
    protocol RollingStatementGroupStore {
        func find(_ code: String) -> RollingStatementGroup?
        func save(_ item: RollingStatementGroup)
        func remove(_ code: String) -> Bool
        func list() -> [RollingStatementGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingStatementGroupStore: RollingStatementGroupStore {
        var items: [String: RollingStatementGroup]
        var order: [String]

        init(items: [String: RollingStatementGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingStatementGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingStatementGroup) {
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

        func list() -> [RollingStatementGroup] {
            var out: [RollingStatementGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingStatementGroupStore() -> any RollingStatementGroupStore {
        return MemoryRollingStatementGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingStatementGroupStore: RollingStatementGroupStore {
        var inner: MemoryRollingStatementGroupStore
        var cache: TTLCache<RollingStatementGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingStatementGroupStore, cache: TTLCache<RollingStatementGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingStatementGroup? {
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

        func save(_ item: RollingStatementGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingStatementGroup] {
            return inner.list()
        }
    }

    static func newCachedRollingStatementGroupStore(_ inner: MemoryRollingStatementGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingStatementGroupStore {
        return CachedRollingStatementGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling statement groups. Empty fields match all.
    final class RollingStatementGroupQuery {
        var ward: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingStatementGroup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingStatementGroup]) -> [RollingStatementGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingStatementGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingStatementGroups(_ store: any RollingStatementGroupStore, query: RollingStatementGroupQuery) -> [RollingStatementGroup] {
        return query.apply(store.list())
    }
}
