import AcmePlatform
import Foundation

extension Consent {
    /// Keeps strict consent form windows by code.
    protocol StrictConsentFormWindowStore {
        func find(_ code: String) -> StrictConsentFormWindow?
        func save(_ item: StrictConsentFormWindow)
        func remove(_ code: String) -> Bool
        func list() -> [StrictConsentFormWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictConsentFormWindowStore: StrictConsentFormWindowStore {
        var items: [String: StrictConsentFormWindow]
        var order: [String]

        init(items: [String: StrictConsentFormWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictConsentFormWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictConsentFormWindow) {
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

        func list() -> [StrictConsentFormWindow] {
            var out: [StrictConsentFormWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictConsentFormWindowStore() -> any StrictConsentFormWindowStore {
        return MemoryStrictConsentFormWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictConsentFormWindowStore: StrictConsentFormWindowStore {
        var inner: MemoryStrictConsentFormWindowStore
        var cache: TTLCache<StrictConsentFormWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictConsentFormWindowStore, cache: TTLCache<StrictConsentFormWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictConsentFormWindow? {
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

        func save(_ item: StrictConsentFormWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictConsentFormWindow] {
            return inner.list()
        }
    }

    static func newCachedStrictConsentFormWindowStore(_ inner: MemoryStrictConsentFormWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictConsentFormWindowStore {
        return CachedStrictConsentFormWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict consent form windows. Empty fields match all.
    final class StrictConsentFormWindowQuery {
        var segment: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictConsentFormWindow) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictConsentFormWindow]) -> [StrictConsentFormWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictConsentFormWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictConsentFormWindows(_ store: any StrictConsentFormWindowStore, query: StrictConsentFormWindowQuery) -> [StrictConsentFormWindow] {
        return query.apply(store.list())
    }
}
