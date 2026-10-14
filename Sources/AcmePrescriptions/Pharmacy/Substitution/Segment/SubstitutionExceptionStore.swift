import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution exceptions by code.
    protocol SubstitutionExceptionStore {
        func find(_ code: String) -> SubstitutionException?
        func save(_ item: SubstitutionException)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionExceptionStore: SubstitutionExceptionStore {
        var items: [String: SubstitutionException]
        var order: [String]

        init(items: [String: SubstitutionException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionException) {
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

        func list() -> [SubstitutionException] {
            var out: [SubstitutionException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionExceptionStore() -> any SubstitutionExceptionStore {
        return MemorySubstitutionExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionExceptionStore: SubstitutionExceptionStore {
        var inner: MemorySubstitutionExceptionStore
        var cache: TTLCache<SubstitutionException>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionExceptionStore, cache: TTLCache<SubstitutionException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionException? {
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

        func save(_ item: SubstitutionException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionException] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionExceptionStore(_ inner: MemorySubstitutionExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionExceptionStore {
        return CachedSubstitutionExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution exceptions. Empty fields match all.
    final class SubstitutionExceptionQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionException]) -> [SubstitutionException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionExceptions(_ store: any SubstitutionExceptionStore, query: SubstitutionExceptionQuery) -> [SubstitutionException] {
        return query.apply(store.list())
    }
}
