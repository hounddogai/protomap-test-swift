import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution windows by code.
    protocol SubstitutionWindowStore {
        func find(_ code: String) -> SubstitutionWindow?
        func save(_ item: SubstitutionWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionWindowStore: SubstitutionWindowStore {
        var items: [String: SubstitutionWindow]
        var order: [String]

        init(items: [String: SubstitutionWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionWindow) {
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

        func list() -> [SubstitutionWindow] {
            var out: [SubstitutionWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionWindowStore() -> any SubstitutionWindowStore {
        return MemorySubstitutionWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionWindowStore: SubstitutionWindowStore {
        var inner: MemorySubstitutionWindowStore
        var cache: TTLCache<SubstitutionWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionWindowStore, cache: TTLCache<SubstitutionWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionWindow? {
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

        func save(_ item: SubstitutionWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionWindow] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionWindowStore(_ inner: MemorySubstitutionWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionWindowStore {
        return CachedSubstitutionWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution windows. Empty fields match all.
    final class SubstitutionWindowQuery {
        var category: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [SubstitutionWindow]) -> [SubstitutionWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionWindows(_ store: any SubstitutionWindowStore, query: SubstitutionWindowQuery) -> [SubstitutionWindow] {
        return query.apply(store.list())
    }
}
