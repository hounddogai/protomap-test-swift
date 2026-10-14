import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution groups by code.
    protocol SubstitutionGroupStore {
        func find(_ code: String) -> SubstitutionGroup?
        func save(_ item: SubstitutionGroup)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionGroupStore: SubstitutionGroupStore {
        var items: [String: SubstitutionGroup]
        var order: [String]

        init(items: [String: SubstitutionGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionGroup) {
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

        func list() -> [SubstitutionGroup] {
            var out: [SubstitutionGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionGroupStore() -> any SubstitutionGroupStore {
        return MemorySubstitutionGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionGroupStore: SubstitutionGroupStore {
        var inner: MemorySubstitutionGroupStore
        var cache: TTLCache<SubstitutionGroup>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionGroupStore, cache: TTLCache<SubstitutionGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionGroup? {
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

        func save(_ item: SubstitutionGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionGroup] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionGroupStore(_ inner: MemorySubstitutionGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionGroupStore {
        return CachedSubstitutionGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution groups. Empty fields match all.
    final class SubstitutionGroupQuery {
        var locale: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minLimit: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionGroup) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionGroup]) -> [SubstitutionGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionGroups(_ store: any SubstitutionGroupStore, query: SubstitutionGroupQuery) -> [SubstitutionGroup] {
        return query.apply(store.list())
    }
}
