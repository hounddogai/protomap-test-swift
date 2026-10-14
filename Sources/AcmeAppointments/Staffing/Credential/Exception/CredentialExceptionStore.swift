import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential exceptions by code.
    protocol CredentialExceptionStore {
        func find(_ code: String) -> CredentialException?
        func save(_ item: CredentialException)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialExceptionStore: CredentialExceptionStore {
        var items: [String: CredentialException]
        var order: [String]

        init(items: [String: CredentialException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialException) {
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

        func list() -> [CredentialException] {
            var out: [CredentialException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialExceptionStore() -> any CredentialExceptionStore {
        return MemoryCredentialExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialExceptionStore: CredentialExceptionStore {
        var inner: MemoryCredentialExceptionStore
        var cache: TTLCache<CredentialException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialExceptionStore, cache: TTLCache<CredentialException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialException? {
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

        func save(_ item: CredentialException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialException] {
            return inner.list()
        }
    }

    static func newCachedCredentialExceptionStore(_ inner: MemoryCredentialExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialExceptionStore {
        return CachedCredentialExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential exceptions. Empty fields match all.
    final class CredentialExceptionQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialException) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialException]) -> [CredentialException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialExceptions(_ store: any CredentialExceptionStore, query: CredentialExceptionQuery) -> [CredentialException] {
        return query.apply(store.list())
    }
}
