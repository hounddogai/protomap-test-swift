import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default shift profiles by code.
    protocol DefaultShiftProfileStore {
        func find(_ code: String) -> DefaultShiftProfile?
        func save(_ item: DefaultShiftProfile)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultShiftProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultShiftProfileStore: DefaultShiftProfileStore {
        var items: [String: DefaultShiftProfile]
        var order: [String]

        init(items: [String: DefaultShiftProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultShiftProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultShiftProfile) {
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

        func list() -> [DefaultShiftProfile] {
            var out: [DefaultShiftProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultShiftProfileStore() -> any DefaultShiftProfileStore {
        return MemoryDefaultShiftProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultShiftProfileStore: DefaultShiftProfileStore {
        var inner: MemoryDefaultShiftProfileStore
        var cache: TTLCache<DefaultShiftProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultShiftProfileStore, cache: TTLCache<DefaultShiftProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultShiftProfile? {
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

        func save(_ item: DefaultShiftProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultShiftProfile] {
            return inner.list()
        }
    }

    static func newCachedDefaultShiftProfileStore(_ inner: MemoryDefaultShiftProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultShiftProfileStore {
        return CachedDefaultShiftProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default shift profiles. Empty fields match all.
    final class DefaultShiftProfileQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultShiftProfile) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [DefaultShiftProfile]) -> [DefaultShiftProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultShiftProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultShiftProfiles(_ store: any DefaultShiftProfileStore, query: DefaultShiftProfileQuery) -> [DefaultShiftProfile] {
        return query.apply(store.list())
    }
}
