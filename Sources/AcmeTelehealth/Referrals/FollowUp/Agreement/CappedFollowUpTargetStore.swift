import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped follow up targets by code.
    protocol CappedFollowUpTargetStore {
        func find(_ code: String) -> CappedFollowUpTarget?
        func save(_ item: CappedFollowUpTarget)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFollowUpTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFollowUpTargetStore: CappedFollowUpTargetStore {
        var items: [String: CappedFollowUpTarget]
        var order: [String]

        init(items: [String: CappedFollowUpTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFollowUpTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFollowUpTarget) {
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

        func list() -> [CappedFollowUpTarget] {
            var out: [CappedFollowUpTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFollowUpTargetStore() -> any CappedFollowUpTargetStore {
        return MemoryCappedFollowUpTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFollowUpTargetStore: CappedFollowUpTargetStore {
        var inner: MemoryCappedFollowUpTargetStore
        var cache: TTLCache<CappedFollowUpTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFollowUpTargetStore, cache: TTLCache<CappedFollowUpTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFollowUpTarget? {
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

        func save(_ item: CappedFollowUpTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFollowUpTarget] {
            return inner.list()
        }
    }

    static func newCachedCappedFollowUpTargetStore(_ inner: MemoryCappedFollowUpTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFollowUpTargetStore {
        return CachedCappedFollowUpTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped follow up targets. Empty fields match all.
    final class CappedFollowUpTargetQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedFollowUpTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedFollowUpTarget]) -> [CappedFollowUpTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFollowUpTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFollowUpTargets(_ store: any CappedFollowUpTargetStore, query: CappedFollowUpTargetQuery) -> [CappedFollowUpTarget] {
        return query.apply(store.list())
    }
}
