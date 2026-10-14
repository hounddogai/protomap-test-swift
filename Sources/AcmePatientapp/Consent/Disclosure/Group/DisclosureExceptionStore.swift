import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure exceptions by code.
    protocol DisclosureExceptionStore {
        func find(_ code: String) -> DisclosureException?
        func save(_ item: DisclosureException)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureExceptionStore: DisclosureExceptionStore {
        var items: [String: DisclosureException]
        var order: [String]

        init(items: [String: DisclosureException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureException) {
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

        func list() -> [DisclosureException] {
            var out: [DisclosureException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureExceptionStore() -> any DisclosureExceptionStore {
        return MemoryDisclosureExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureExceptionStore: DisclosureExceptionStore {
        var inner: MemoryDisclosureExceptionStore
        var cache: TTLCache<DisclosureException>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureExceptionStore, cache: TTLCache<DisclosureException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureException? {
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

        func save(_ item: DisclosureException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureException] {
            return inner.list()
        }
    }

    static func newCachedDisclosureExceptionStore(_ inner: MemoryDisclosureExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureExceptionStore {
        return CachedDisclosureExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure exceptions. Empty fields match all.
    final class DisclosureExceptionQuery {
        var facility: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureException) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureException]) -> [DisclosureException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureExceptions(_ store: any DisclosureExceptionStore, query: DisclosureExceptionQuery) -> [DisclosureException] {
        return query.apply(store.list())
    }
}
