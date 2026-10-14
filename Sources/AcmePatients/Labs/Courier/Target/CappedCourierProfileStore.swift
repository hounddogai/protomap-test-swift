import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped courier profiles by code.
    protocol CappedCourierProfileStore {
        func find(_ code: String) -> CappedCourierProfile?
        func save(_ item: CappedCourierProfile)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCourierProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCourierProfileStore: CappedCourierProfileStore {
        var items: [String: CappedCourierProfile]
        var order: [String]

        init(items: [String: CappedCourierProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCourierProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCourierProfile) {
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

        func list() -> [CappedCourierProfile] {
            var out: [CappedCourierProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCourierProfileStore() -> any CappedCourierProfileStore {
        return MemoryCappedCourierProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCourierProfileStore: CappedCourierProfileStore {
        var inner: MemoryCappedCourierProfileStore
        var cache: TTLCache<CappedCourierProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCourierProfileStore, cache: TTLCache<CappedCourierProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCourierProfile? {
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

        func save(_ item: CappedCourierProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCourierProfile] {
            return inner.list()
        }
    }

    static func newCachedCappedCourierProfileStore(_ inner: MemoryCappedCourierProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCourierProfileStore {
        return CachedCappedCourierProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped courier profiles. Empty fields match all.
    final class CappedCourierProfileQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCourierProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCourierProfile]) -> [CappedCourierProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCourierProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCourierProfiles(_ store: any CappedCourierProfileStore, query: CappedCourierProfileQuery) -> [CappedCourierProfile] {
        return query.apply(store.list())
    }
}
