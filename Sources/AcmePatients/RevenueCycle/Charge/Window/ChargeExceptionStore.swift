import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge exceptions by code.
    protocol ChargeExceptionStore {
        func find(_ code: String) -> ChargeException?
        func save(_ item: ChargeException)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeExceptionStore: ChargeExceptionStore {
        var items: [String: ChargeException]
        var order: [String]

        init(items: [String: ChargeException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeException) {
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

        func list() -> [ChargeException] {
            var out: [ChargeException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeExceptionStore() -> any ChargeExceptionStore {
        return MemoryChargeExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeExceptionStore: ChargeExceptionStore {
        var inner: MemoryChargeExceptionStore
        var cache: TTLCache<ChargeException>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeExceptionStore, cache: TTLCache<ChargeException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeException? {
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

        func save(_ item: ChargeException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeException] {
            return inner.list()
        }
    }

    static func newCachedChargeExceptionStore(_ inner: MemoryChargeExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeExceptionStore {
        return CachedChargeExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge exceptions. Empty fields match all.
    final class ChargeExceptionQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeException]) -> [ChargeException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeExceptions(_ store: any ChargeExceptionStore, query: ChargeExceptionQuery) -> [ChargeException] {
        return query.apply(store.list())
    }
}
