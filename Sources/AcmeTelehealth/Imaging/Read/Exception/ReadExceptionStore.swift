import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read exceptions by code.
    protocol ReadExceptionStore {
        func find(_ code: String) -> ReadException?
        func save(_ item: ReadException)
        func remove(_ code: String) -> Bool
        func list() -> [ReadException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadExceptionStore: ReadExceptionStore {
        var items: [String: ReadException]
        var order: [String]

        init(items: [String: ReadException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadException) {
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

        func list() -> [ReadException] {
            var out: [ReadException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadExceptionStore() -> any ReadExceptionStore {
        return MemoryReadExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadExceptionStore: ReadExceptionStore {
        var inner: MemoryReadExceptionStore
        var cache: TTLCache<ReadException>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadExceptionStore, cache: TTLCache<ReadException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadException? {
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

        func save(_ item: ReadException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadException] {
            return inner.list()
        }
    }

    static func newCachedReadExceptionStore(_ inner: MemoryReadExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadExceptionStore {
        return CachedReadExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read exceptions. Empty fields match all.
    final class ReadExceptionQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadException) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [ReadException]) -> [ReadException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadExceptions(_ store: any ReadExceptionStore, query: ReadExceptionQuery) -> [ReadException] {
        return query.apply(store.list())
    }
}
