import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps rolling closure profiles by code.
    protocol RollingClosureProfileStore {
        func find(_ code: String) -> RollingClosureProfile?
        func save(_ item: RollingClosureProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RollingClosureProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingClosureProfileStore: RollingClosureProfileStore {
        var items: [String: RollingClosureProfile]
        var order: [String]

        init(items: [String: RollingClosureProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingClosureProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingClosureProfile) {
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

        func list() -> [RollingClosureProfile] {
            var out: [RollingClosureProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingClosureProfileStore() -> any RollingClosureProfileStore {
        return MemoryRollingClosureProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingClosureProfileStore: RollingClosureProfileStore {
        var inner: MemoryRollingClosureProfileStore
        var cache: TTLCache<RollingClosureProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingClosureProfileStore, cache: TTLCache<RollingClosureProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingClosureProfile? {
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

        func save(_ item: RollingClosureProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingClosureProfile] {
            return inner.list()
        }
    }

    static func newCachedRollingClosureProfileStore(_ inner: MemoryRollingClosureProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingClosureProfileStore {
        return CachedRollingClosureProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling closure profiles. Empty fields match all.
    final class RollingClosureProfileQuery {
        var ward: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingClosureProfile) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingClosureProfile]) -> [RollingClosureProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingClosureProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingClosureProfiles(_ store: any RollingClosureProfileStore, query: RollingClosureProfileQuery) -> [RollingClosureProfile] {
        return query.apply(store.list())
    }
}
