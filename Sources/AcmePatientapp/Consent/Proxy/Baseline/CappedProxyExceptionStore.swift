import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped proxy exceptions by code.
    protocol CappedProxyExceptionStore {
        func find(_ code: String) -> CappedProxyException?
        func save(_ item: CappedProxyException)
        func remove(_ code: String) -> Bool
        func list() -> [CappedProxyException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedProxyExceptionStore: CappedProxyExceptionStore {
        var items: [String: CappedProxyException]
        var order: [String]

        init(items: [String: CappedProxyException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedProxyException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedProxyException) {
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

        func list() -> [CappedProxyException] {
            var out: [CappedProxyException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedProxyExceptionStore() -> any CappedProxyExceptionStore {
        return MemoryCappedProxyExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedProxyExceptionStore: CappedProxyExceptionStore {
        var inner: MemoryCappedProxyExceptionStore
        var cache: TTLCache<CappedProxyException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedProxyExceptionStore, cache: TTLCache<CappedProxyException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedProxyException? {
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

        func save(_ item: CappedProxyException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedProxyException] {
            return inner.list()
        }
    }

    static func newCachedCappedProxyExceptionStore(_ inner: MemoryCappedProxyExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedProxyExceptionStore {
        return CachedCappedProxyExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped proxy exceptions. Empty fields match all.
    final class CappedProxyExceptionQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedProxyException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedProxyException]) -> [CappedProxyException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedProxyException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedProxyExceptions(_ store: any CappedProxyExceptionStore, query: CappedProxyExceptionQuery) -> [CappedProxyException] {
        return query.apply(store.list())
    }
}
