import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning exceptions by code.
    protocol CleaningExceptionStore {
        func find(_ code: String) -> CleaningException?
        func save(_ item: CleaningException)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningExceptionStore: CleaningExceptionStore {
        var items: [String: CleaningException]
        var order: [String]

        init(items: [String: CleaningException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningException) {
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

        func list() -> [CleaningException] {
            var out: [CleaningException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningExceptionStore() -> any CleaningExceptionStore {
        return MemoryCleaningExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningExceptionStore: CleaningExceptionStore {
        var inner: MemoryCleaningExceptionStore
        var cache: TTLCache<CleaningException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningExceptionStore, cache: TTLCache<CleaningException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningException? {
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

        func save(_ item: CleaningException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningException] {
            return inner.list()
        }
    }

    static func newCachedCleaningExceptionStore(_ inner: MemoryCleaningExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningExceptionStore {
        return CachedCleaningExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning exceptions. Empty fields match all.
    final class CleaningExceptionQuery {
        var source: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minWeight: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningException) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningException]) -> [CleaningException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningExceptions(_ store: any CleaningExceptionStore, query: CleaningExceptionQuery) -> [CleaningException] {
        return query.apply(store.list())
    }
}
