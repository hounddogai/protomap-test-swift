import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up targets by code.
    protocol FollowUpTargetStore {
        func find(_ code: String) -> FollowUpTarget?
        func save(_ item: FollowUpTarget)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpTargetStore: FollowUpTargetStore {
        var items: [String: FollowUpTarget]
        var order: [String]

        init(items: [String: FollowUpTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpTarget) {
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

        func list() -> [FollowUpTarget] {
            var out: [FollowUpTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpTargetStore() -> any FollowUpTargetStore {
        return MemoryFollowUpTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpTargetStore: FollowUpTargetStore {
        var inner: MemoryFollowUpTargetStore
        var cache: TTLCache<FollowUpTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpTargetStore, cache: TTLCache<FollowUpTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpTarget? {
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

        func save(_ item: FollowUpTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpTarget] {
            return inner.list()
        }
    }

    static func newCachedFollowUpTargetStore(_ inner: MemoryFollowUpTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpTargetStore {
        return CachedFollowUpTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up targets. Empty fields match all.
    final class FollowUpTargetQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [FollowUpTarget]) -> [FollowUpTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpTargets(_ store: any FollowUpTargetStore, query: FollowUpTargetQuery) -> [FollowUpTarget] {
        return query.apply(store.list())
    }
}
