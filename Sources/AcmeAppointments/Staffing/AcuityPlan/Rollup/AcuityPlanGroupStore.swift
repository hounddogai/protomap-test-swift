import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan groups by code.
    protocol AcuityPlanGroupStore {
        func find(_ code: String) -> AcuityPlanGroup?
        func save(_ item: AcuityPlanGroup)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanGroupStore: AcuityPlanGroupStore {
        var items: [String: AcuityPlanGroup]
        var order: [String]

        init(items: [String: AcuityPlanGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanGroup) {
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

        func list() -> [AcuityPlanGroup] {
            var out: [AcuityPlanGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanGroupStore() -> any AcuityPlanGroupStore {
        return MemoryAcuityPlanGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanGroupStore: AcuityPlanGroupStore {
        var inner: MemoryAcuityPlanGroupStore
        var cache: TTLCache<AcuityPlanGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanGroupStore, cache: TTLCache<AcuityPlanGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanGroup? {
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

        func save(_ item: AcuityPlanGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanGroup] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanGroupStore(_ inner: MemoryAcuityPlanGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanGroupStore {
        return CachedAcuityPlanGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan groups. Empty fields match all.
    final class AcuityPlanGroupQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanGroup]) -> [AcuityPlanGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanGroups(_ store: any AcuityPlanGroupStore, query: AcuityPlanGroupQuery) -> [AcuityPlanGroup] {
        return query.apply(store.list())
    }
}
