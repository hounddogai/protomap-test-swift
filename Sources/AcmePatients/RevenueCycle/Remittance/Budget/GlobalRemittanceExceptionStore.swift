import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global remittance exceptions by code.
    protocol GlobalRemittanceExceptionStore {
        func find(_ code: String) -> GlobalRemittanceException?
        func save(_ item: GlobalRemittanceException)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRemittanceException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRemittanceExceptionStore: GlobalRemittanceExceptionStore {
        var items: [String: GlobalRemittanceException]
        var order: [String]

        init(items: [String: GlobalRemittanceException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRemittanceException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRemittanceException) {
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

        func list() -> [GlobalRemittanceException] {
            var out: [GlobalRemittanceException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRemittanceExceptionStore() -> any GlobalRemittanceExceptionStore {
        return MemoryGlobalRemittanceExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRemittanceExceptionStore: GlobalRemittanceExceptionStore {
        var inner: MemoryGlobalRemittanceExceptionStore
        var cache: TTLCache<GlobalRemittanceException>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRemittanceExceptionStore, cache: TTLCache<GlobalRemittanceException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRemittanceException? {
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

        func save(_ item: GlobalRemittanceException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRemittanceException] {
            return inner.list()
        }
    }

    static func newCachedGlobalRemittanceExceptionStore(_ inner: MemoryGlobalRemittanceExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRemittanceExceptionStore {
        return CachedGlobalRemittanceExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global remittance exceptions. Empty fields match all.
    final class GlobalRemittanceExceptionQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRemittanceException) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalRemittanceException]) -> [GlobalRemittanceException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRemittanceException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRemittanceExceptions(_ store: any GlobalRemittanceExceptionStore, query: GlobalRemittanceExceptionQuery) -> [GlobalRemittanceException] {
        return query.apply(store.list())
    }
}
