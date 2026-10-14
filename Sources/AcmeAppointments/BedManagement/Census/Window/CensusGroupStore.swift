import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census groups by code.
    protocol CensusGroupStore {
        func find(_ code: String) -> CensusGroup?
        func save(_ item: CensusGroup)
        func remove(_ code: String) -> Bool
        func list() -> [CensusGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusGroupStore: CensusGroupStore {
        var items: [String: CensusGroup]
        var order: [String]

        init(items: [String: CensusGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusGroup) {
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

        func list() -> [CensusGroup] {
            var out: [CensusGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusGroupStore() -> any CensusGroupStore {
        return MemoryCensusGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusGroupStore: CensusGroupStore {
        var inner: MemoryCensusGroupStore
        var cache: TTLCache<CensusGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusGroupStore, cache: TTLCache<CensusGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusGroup? {
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

        func save(_ item: CensusGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusGroup] {
            return inner.list()
        }
    }

    static func newCachedCensusGroupStore(_ inner: MemoryCensusGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusGroupStore {
        return CachedCensusGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census groups. Empty fields match all.
    final class CensusGroupQuery {
        var segment: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVersion: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusGroup]) -> [CensusGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusGroups(_ store: any CensusGroupStore, query: CensusGroupQuery) -> [CensusGroup] {
        return query.apply(store.list())
    }
}
