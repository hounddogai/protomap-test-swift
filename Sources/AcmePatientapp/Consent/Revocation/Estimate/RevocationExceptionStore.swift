import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation exceptions by code.
    protocol RevocationExceptionStore {
        func find(_ code: String) -> RevocationException?
        func save(_ item: RevocationException)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationExceptionStore: RevocationExceptionStore {
        var items: [String: RevocationException]
        var order: [String]

        init(items: [String: RevocationException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationException) {
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

        func list() -> [RevocationException] {
            var out: [RevocationException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationExceptionStore() -> any RevocationExceptionStore {
        return MemoryRevocationExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationExceptionStore: RevocationExceptionStore {
        var inner: MemoryRevocationExceptionStore
        var cache: TTLCache<RevocationException>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationExceptionStore, cache: TTLCache<RevocationException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationException? {
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

        func save(_ item: RevocationException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationException] {
            return inner.list()
        }
    }

    static func newCachedRevocationExceptionStore(_ inner: MemoryRevocationExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationExceptionStore {
        return CachedRevocationExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation exceptions. Empty fields match all.
    final class RevocationExceptionQuery {
        var channel: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationException) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationException]) -> [RevocationException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationExceptions(_ store: any RevocationExceptionStore, query: RevocationExceptionQuery) -> [RevocationException] {
        return query.apply(store.list())
    }
}
