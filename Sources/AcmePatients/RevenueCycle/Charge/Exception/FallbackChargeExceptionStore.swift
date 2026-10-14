import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback charge exceptions by code.
    protocol FallbackChargeExceptionStore {
        func find(_ code: String) -> FallbackChargeException?
        func save(_ item: FallbackChargeException)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackChargeException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackChargeExceptionStore: FallbackChargeExceptionStore {
        var items: [String: FallbackChargeException]
        var order: [String]

        init(items: [String: FallbackChargeException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackChargeException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackChargeException) {
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

        func list() -> [FallbackChargeException] {
            var out: [FallbackChargeException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackChargeExceptionStore() -> any FallbackChargeExceptionStore {
        return MemoryFallbackChargeExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackChargeExceptionStore: FallbackChargeExceptionStore {
        var inner: MemoryFallbackChargeExceptionStore
        var cache: TTLCache<FallbackChargeException>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackChargeExceptionStore, cache: TTLCache<FallbackChargeException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackChargeException? {
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

        func save(_ item: FallbackChargeException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackChargeException] {
            return inner.list()
        }
    }

    static func newCachedFallbackChargeExceptionStore(_ inner: MemoryFallbackChargeExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackChargeExceptionStore {
        return CachedFallbackChargeExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback charge exceptions. Empty fields match all.
    final class FallbackChargeExceptionQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackChargeException) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackChargeException]) -> [FallbackChargeException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackChargeException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackChargeExceptions(_ store: any FallbackChargeExceptionStore, query: FallbackChargeExceptionQuery) -> [FallbackChargeException] {
        return query.apply(store.list())
    }
}
