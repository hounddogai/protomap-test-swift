import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix requests by code.
    protocol SkillMixRequestStore {
        func find(_ code: String) -> SkillMixRequest?
        func save(_ item: SkillMixRequest)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixRequestStore: SkillMixRequestStore {
        var items: [String: SkillMixRequest]
        var order: [String]

        init(items: [String: SkillMixRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixRequest) {
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

        func list() -> [SkillMixRequest] {
            var out: [SkillMixRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixRequestStore() -> any SkillMixRequestStore {
        return MemorySkillMixRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixRequestStore: SkillMixRequestStore {
        var inner: MemorySkillMixRequestStore
        var cache: TTLCache<SkillMixRequest>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixRequestStore, cache: TTLCache<SkillMixRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixRequest? {
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

        func save(_ item: SkillMixRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixRequest] {
            return inner.list()
        }
    }

    static func newCachedSkillMixRequestStore(_ inner: MemorySkillMixRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixRequestStore {
        return CachedSkillMixRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix requests. Empty fields match all.
    final class SkillMixRequestQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixRequest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [SkillMixRequest]) -> [SkillMixRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixRequests(_ store: any SkillMixRequestStore, query: SkillMixRequestQuery) -> [SkillMixRequest] {
        return query.apply(store.list())
    }
}
