import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient dispense requests by code.
    protocol LenientDispenseRequestStore {
        func find(_ code: String) -> LenientDispenseRequest?
        func save(_ item: LenientDispenseRequest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDispenseRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDispenseRequestStore: LenientDispenseRequestStore {
        var items: [String: LenientDispenseRequest]
        var order: [String]

        init(items: [String: LenientDispenseRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDispenseRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDispenseRequest) {
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

        func list() -> [LenientDispenseRequest] {
            var out: [LenientDispenseRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDispenseRequestStore() -> any LenientDispenseRequestStore {
        return MemoryLenientDispenseRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDispenseRequestStore: LenientDispenseRequestStore {
        var inner: MemoryLenientDispenseRequestStore
        var cache: TTLCache<LenientDispenseRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDispenseRequestStore, cache: TTLCache<LenientDispenseRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDispenseRequest? {
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

        func save(_ item: LenientDispenseRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDispenseRequest] {
            return inner.list()
        }
    }

    static func newCachedLenientDispenseRequestStore(_ inner: MemoryLenientDispenseRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDispenseRequestStore {
        return CachedLenientDispenseRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient dispense requests. Empty fields match all.
    final class LenientDispenseRequestQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientDispenseRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientDispenseRequest]) -> [LenientDispenseRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDispenseRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDispenseRequests(_ store: any LenientDispenseRequestStore, query: LenientDispenseRequestQuery) -> [LenientDispenseRequest] {
        return query.apply(store.list())
    }
}
