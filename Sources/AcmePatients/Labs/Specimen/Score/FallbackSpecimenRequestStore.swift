import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback specimen requests by code.
    protocol FallbackSpecimenRequestStore {
        func find(_ code: String) -> FallbackSpecimenRequest?
        func save(_ item: FallbackSpecimenRequest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSpecimenRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSpecimenRequestStore: FallbackSpecimenRequestStore {
        var items: [String: FallbackSpecimenRequest]
        var order: [String]

        init(items: [String: FallbackSpecimenRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSpecimenRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSpecimenRequest) {
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

        func list() -> [FallbackSpecimenRequest] {
            var out: [FallbackSpecimenRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSpecimenRequestStore() -> any FallbackSpecimenRequestStore {
        return MemoryFallbackSpecimenRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSpecimenRequestStore: FallbackSpecimenRequestStore {
        var inner: MemoryFallbackSpecimenRequestStore
        var cache: TTLCache<FallbackSpecimenRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSpecimenRequestStore, cache: TTLCache<FallbackSpecimenRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSpecimenRequest? {
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

        func save(_ item: FallbackSpecimenRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSpecimenRequest] {
            return inner.list()
        }
    }

    static func newCachedFallbackSpecimenRequestStore(_ inner: MemoryFallbackSpecimenRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSpecimenRequestStore {
        return CachedFallbackSpecimenRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback specimen requests. Empty fields match all.
    final class FallbackSpecimenRequestQuery {
        var locale: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSpecimenRequest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackSpecimenRequest]) -> [FallbackSpecimenRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSpecimenRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSpecimenRequests(_ store: any FallbackSpecimenRequestStore, query: FallbackSpecimenRequestQuery) -> [FallbackSpecimenRequest] {
        return query.apply(store.list())
    }
}
