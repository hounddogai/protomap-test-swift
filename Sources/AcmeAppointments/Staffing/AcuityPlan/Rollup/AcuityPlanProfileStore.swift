import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan profiles by code.
    protocol AcuityPlanProfileStore {
        func find(_ code: String) -> AcuityPlanProfile?
        func save(_ item: AcuityPlanProfile)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanProfileStore: AcuityPlanProfileStore {
        var items: [String: AcuityPlanProfile]
        var order: [String]

        init(items: [String: AcuityPlanProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanProfile) {
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

        func list() -> [AcuityPlanProfile] {
            var out: [AcuityPlanProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanProfileStore() -> any AcuityPlanProfileStore {
        return MemoryAcuityPlanProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanProfileStore: AcuityPlanProfileStore {
        var inner: MemoryAcuityPlanProfileStore
        var cache: TTLCache<AcuityPlanProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanProfileStore, cache: TTLCache<AcuityPlanProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanProfile? {
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

        func save(_ item: AcuityPlanProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanProfile] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanProfileStore(_ inner: MemoryAcuityPlanProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanProfileStore {
        return CachedAcuityPlanProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan profiles. Empty fields match all.
    final class AcuityPlanProfileQuery {
        var ward: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minPriority: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanProfile) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanProfile]) -> [AcuityPlanProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanProfiles(_ store: any AcuityPlanProfileStore, query: AcuityPlanProfileQuery) -> [AcuityPlanProfile] {
        return query.apply(store.list())
    }
}
