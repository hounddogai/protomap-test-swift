import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive study groups by code.
    protocol AdaptiveStudyGroupStore {
        func find(_ code: String) -> AdaptiveStudyGroup?
        func save(_ item: AdaptiveStudyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStudyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStudyGroupStore: AdaptiveStudyGroupStore {
        var items: [String: AdaptiveStudyGroup]
        var order: [String]

        init(items: [String: AdaptiveStudyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStudyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStudyGroup) {
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

        func list() -> [AdaptiveStudyGroup] {
            var out: [AdaptiveStudyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStudyGroupStore() -> any AdaptiveStudyGroupStore {
        return MemoryAdaptiveStudyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStudyGroupStore: AdaptiveStudyGroupStore {
        var inner: MemoryAdaptiveStudyGroupStore
        var cache: TTLCache<AdaptiveStudyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStudyGroupStore, cache: TTLCache<AdaptiveStudyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStudyGroup? {
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

        func save(_ item: AdaptiveStudyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStudyGroup] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStudyGroupStore(_ inner: MemoryAdaptiveStudyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStudyGroupStore {
        return CachedAdaptiveStudyGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive study groups. Empty fields match all.
    final class AdaptiveStudyGroupQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStudyGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveStudyGroup]) -> [AdaptiveStudyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStudyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStudyGroups(_ store: any AdaptiveStudyGroupStore, query: AdaptiveStudyGroupQuery) -> [AdaptiveStudyGroup] {
        return query.apply(store.list())
    }
}
