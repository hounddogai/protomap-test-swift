import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending skill mix requests by code.
    protocol PendingSkillMixRequestStore {
        func find(_ code: String) -> PendingSkillMixRequest?
        func save(_ item: PendingSkillMixRequest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingSkillMixRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingSkillMixRequestStore: PendingSkillMixRequestStore {
        var items: [String: PendingSkillMixRequest]
        var order: [String]

        init(items: [String: PendingSkillMixRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingSkillMixRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingSkillMixRequest) {
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

        func list() -> [PendingSkillMixRequest] {
            var out: [PendingSkillMixRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingSkillMixRequestStore() -> any PendingSkillMixRequestStore {
        return MemoryPendingSkillMixRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingSkillMixRequestStore: PendingSkillMixRequestStore {
        var inner: MemoryPendingSkillMixRequestStore
        var cache: TTLCache<PendingSkillMixRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingSkillMixRequestStore, cache: TTLCache<PendingSkillMixRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingSkillMixRequest? {
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

        func save(_ item: PendingSkillMixRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingSkillMixRequest] {
            return inner.list()
        }
    }

    static func newCachedPendingSkillMixRequestStore(_ inner: MemoryPendingSkillMixRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingSkillMixRequestStore {
        return CachedPendingSkillMixRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending skill mix requests. Empty fields match all.
    final class PendingSkillMixRequestQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingSkillMixRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingSkillMixRequest]) -> [PendingSkillMixRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingSkillMixRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingSkillMixRequests(_ store: any PendingSkillMixRequestStore, query: PendingSkillMixRequestQuery) -> [PendingSkillMixRequest] {
        return query.apply(store.list())
    }
}
