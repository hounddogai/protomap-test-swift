import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling revocation exceptions by code.
    protocol RollingRevocationExceptionStore {
        func find(_ code: String) -> RollingRevocationException?
        func save(_ item: RollingRevocationException)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRevocationException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRevocationExceptionStore: RollingRevocationExceptionStore {
        var items: [String: RollingRevocationException]
        var order: [String]

        init(items: [String: RollingRevocationException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRevocationException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRevocationException) {
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

        func list() -> [RollingRevocationException] {
            var out: [RollingRevocationException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRevocationExceptionStore() -> any RollingRevocationExceptionStore {
        return MemoryRollingRevocationExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRevocationExceptionStore: RollingRevocationExceptionStore {
        var inner: MemoryRollingRevocationExceptionStore
        var cache: TTLCache<RollingRevocationException>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRevocationExceptionStore, cache: TTLCache<RollingRevocationException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRevocationException? {
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

        func save(_ item: RollingRevocationException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRevocationException] {
            return inner.list()
        }
    }

    static func newCachedRollingRevocationExceptionStore(_ inner: MemoryRollingRevocationExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRevocationExceptionStore {
        return CachedRollingRevocationExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling revocation exceptions. Empty fields match all.
    final class RollingRevocationExceptionQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRevocationException) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRevocationException]) -> [RollingRevocationException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRevocationException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRevocationExceptions(_ store: any RollingRevocationExceptionStore, query: RollingRevocationExceptionQuery) -> [RollingRevocationException] {
        return query.apply(store.list())
    }
}
