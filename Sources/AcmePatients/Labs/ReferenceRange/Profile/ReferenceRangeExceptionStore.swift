import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range exceptions by code.
    protocol ReferenceRangeExceptionStore {
        func find(_ code: String) -> ReferenceRangeException?
        func save(_ item: ReferenceRangeException)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeExceptionStore: ReferenceRangeExceptionStore {
        var items: [String: ReferenceRangeException]
        var order: [String]

        init(items: [String: ReferenceRangeException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeException) {
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

        func list() -> [ReferenceRangeException] {
            var out: [ReferenceRangeException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeExceptionStore() -> any ReferenceRangeExceptionStore {
        return MemoryReferenceRangeExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeExceptionStore: ReferenceRangeExceptionStore {
        var inner: MemoryReferenceRangeExceptionStore
        var cache: TTLCache<ReferenceRangeException>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeExceptionStore, cache: TTLCache<ReferenceRangeException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeException? {
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

        func save(_ item: ReferenceRangeException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeException] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeExceptionStore(_ inner: MemoryReferenceRangeExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeExceptionStore {
        return CachedReferenceRangeExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range exceptions. Empty fields match all.
    final class ReferenceRangeExceptionQuery {
        var category: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeException) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeException]) -> [ReferenceRangeException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeExceptions(_ store: any ReferenceRangeExceptionStore, query: ReferenceRangeExceptionQuery) -> [ReferenceRangeException] {
        return query.apply(store.list())
    }
}
