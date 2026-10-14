import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range groups by code.
    protocol ReferenceRangeGroupStore {
        func find(_ code: String) -> ReferenceRangeGroup?
        func save(_ item: ReferenceRangeGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeGroupStore: ReferenceRangeGroupStore {
        var items: [String: ReferenceRangeGroup]
        var order: [String]

        init(items: [String: ReferenceRangeGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeGroup) {
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

        func list() -> [ReferenceRangeGroup] {
            var out: [ReferenceRangeGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeGroupStore() -> any ReferenceRangeGroupStore {
        return MemoryReferenceRangeGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeGroupStore: ReferenceRangeGroupStore {
        var inner: MemoryReferenceRangeGroupStore
        var cache: TTLCache<ReferenceRangeGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeGroupStore, cache: TTLCache<ReferenceRangeGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeGroup? {
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

        func save(_ item: ReferenceRangeGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeGroup] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeGroupStore(_ inner: MemoryReferenceRangeGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeGroupStore {
        return CachedReferenceRangeGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range groups. Empty fields match all.
    final class ReferenceRangeGroupQuery {
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

        func matches(_ item: ReferenceRangeGroup) -> Bool {
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

        func apply(_ items: [ReferenceRangeGroup]) -> [ReferenceRangeGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeGroups(_ store: any ReferenceRangeGroupStore, query: ReferenceRangeGroupQuery) -> [ReferenceRangeGroup] {
        return query.apply(store.list())
    }
}
