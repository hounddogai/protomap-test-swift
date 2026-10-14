import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient cleaning requests by code.
    protocol LenientCleaningRequestStore {
        func find(_ code: String) -> LenientCleaningRequest?
        func save(_ item: LenientCleaningRequest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCleaningRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCleaningRequestStore: LenientCleaningRequestStore {
        var items: [String: LenientCleaningRequest]
        var order: [String]

        init(items: [String: LenientCleaningRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCleaningRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCleaningRequest) {
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

        func list() -> [LenientCleaningRequest] {
            var out: [LenientCleaningRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCleaningRequestStore() -> any LenientCleaningRequestStore {
        return MemoryLenientCleaningRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCleaningRequestStore: LenientCleaningRequestStore {
        var inner: MemoryLenientCleaningRequestStore
        var cache: TTLCache<LenientCleaningRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCleaningRequestStore, cache: TTLCache<LenientCleaningRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCleaningRequest? {
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

        func save(_ item: LenientCleaningRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCleaningRequest] {
            return inner.list()
        }
    }

    static func newCachedLenientCleaningRequestStore(_ inner: MemoryLenientCleaningRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCleaningRequestStore {
        return CachedLenientCleaningRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient cleaning requests. Empty fields match all.
    final class LenientCleaningRequestQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCleaningRequest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCleaningRequest]) -> [LenientCleaningRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCleaningRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCleaningRequests(_ store: any LenientCleaningRequestStore, query: LenientCleaningRequestQuery) -> [LenientCleaningRequest] {
        return query.apply(store.list())
    }
}
