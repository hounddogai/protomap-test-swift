import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense exceptions by code.
    protocol DispenseExceptionStore {
        func find(_ code: String) -> DispenseException?
        func save(_ item: DispenseException)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseExceptionStore: DispenseExceptionStore {
        var items: [String: DispenseException]
        var order: [String]

        init(items: [String: DispenseException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseException) {
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

        func list() -> [DispenseException] {
            var out: [DispenseException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseExceptionStore() -> any DispenseExceptionStore {
        return MemoryDispenseExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseExceptionStore: DispenseExceptionStore {
        var inner: MemoryDispenseExceptionStore
        var cache: TTLCache<DispenseException>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseExceptionStore, cache: TTLCache<DispenseException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseException? {
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

        func save(_ item: DispenseException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseException] {
            return inner.list()
        }
    }

    static func newCachedDispenseExceptionStore(_ inner: MemoryDispenseExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseExceptionStore {
        return CachedDispenseExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense exceptions. Empty fields match all.
    final class DispenseExceptionQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseException) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseException]) -> [DispenseException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseExceptions(_ store: any DispenseExceptionStore, query: DispenseExceptionQuery) -> [DispenseException] {
        return query.apply(store.list())
    }
}
