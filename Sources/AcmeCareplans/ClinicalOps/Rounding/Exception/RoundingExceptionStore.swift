import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding exceptions by code.
    protocol RoundingExceptionStore {
        func find(_ code: String) -> RoundingException?
        func save(_ item: RoundingException)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingExceptionStore: RoundingExceptionStore {
        var items: [String: RoundingException]
        var order: [String]

        init(items: [String: RoundingException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingException) {
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

        func list() -> [RoundingException] {
            var out: [RoundingException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingExceptionStore() -> any RoundingExceptionStore {
        return MemoryRoundingExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingExceptionStore: RoundingExceptionStore {
        var inner: MemoryRoundingExceptionStore
        var cache: TTLCache<RoundingException>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingExceptionStore, cache: TTLCache<RoundingException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingException? {
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

        func save(_ item: RoundingException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingException] {
            return inner.list()
        }
    }

    static func newCachedRoundingExceptionStore(_ inner: MemoryRoundingExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingExceptionStore {
        return CachedRoundingExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding exceptions. Empty fields match all.
    final class RoundingExceptionQuery {
        var country: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minSequence: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingException) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingException]) -> [RoundingException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingExceptions(_ store: any RoundingExceptionStore, query: RoundingExceptionQuery) -> [RoundingException] {
        return query.apply(store.list())
    }
}
