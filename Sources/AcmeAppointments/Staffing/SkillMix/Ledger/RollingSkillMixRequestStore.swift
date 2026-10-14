import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling skill mix requests by code.
    protocol RollingSkillMixRequestStore {
        func find(_ code: String) -> RollingSkillMixRequest?
        func save(_ item: RollingSkillMixRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingSkillMixRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingSkillMixRequestStore: RollingSkillMixRequestStore {
        var items: [String: RollingSkillMixRequest]
        var order: [String]

        init(items: [String: RollingSkillMixRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingSkillMixRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingSkillMixRequest) {
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

        func list() -> [RollingSkillMixRequest] {
            var out: [RollingSkillMixRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingSkillMixRequestStore() -> any RollingSkillMixRequestStore {
        return MemoryRollingSkillMixRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingSkillMixRequestStore: RollingSkillMixRequestStore {
        var inner: MemoryRollingSkillMixRequestStore
        var cache: TTLCache<RollingSkillMixRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingSkillMixRequestStore, cache: TTLCache<RollingSkillMixRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingSkillMixRequest? {
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

        func save(_ item: RollingSkillMixRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingSkillMixRequest] {
            return inner.list()
        }
    }

    static func newCachedRollingSkillMixRequestStore(_ inner: MemoryRollingSkillMixRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingSkillMixRequestStore {
        return CachedRollingSkillMixRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling skill mix requests. Empty fields match all.
    final class RollingSkillMixRequestQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingSkillMixRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingSkillMixRequest]) -> [RollingSkillMixRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingSkillMixRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingSkillMixRequests(_ store: any RollingSkillMixRequestStore, query: RollingSkillMixRequestQuery) -> [RollingSkillMixRequest] {
        return query.apply(store.list())
    }
}
