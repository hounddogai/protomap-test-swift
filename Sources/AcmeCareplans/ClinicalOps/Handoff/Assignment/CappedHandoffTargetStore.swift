import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped handoff targets by code.
    protocol CappedHandoffTargetStore {
        func find(_ code: String) -> CappedHandoffTarget?
        func save(_ item: CappedHandoffTarget)
        func remove(_ code: String) -> Bool
        func list() -> [CappedHandoffTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedHandoffTargetStore: CappedHandoffTargetStore {
        var items: [String: CappedHandoffTarget]
        var order: [String]

        init(items: [String: CappedHandoffTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedHandoffTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedHandoffTarget) {
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

        func list() -> [CappedHandoffTarget] {
            var out: [CappedHandoffTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedHandoffTargetStore() -> any CappedHandoffTargetStore {
        return MemoryCappedHandoffTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedHandoffTargetStore: CappedHandoffTargetStore {
        var inner: MemoryCappedHandoffTargetStore
        var cache: TTLCache<CappedHandoffTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedHandoffTargetStore, cache: TTLCache<CappedHandoffTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedHandoffTarget? {
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

        func save(_ item: CappedHandoffTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedHandoffTarget] {
            return inner.list()
        }
    }

    static func newCachedCappedHandoffTargetStore(_ inner: MemoryCappedHandoffTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedHandoffTargetStore {
        return CachedCappedHandoffTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped handoff targets. Empty fields match all.
    final class CappedHandoffTargetQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedHandoffTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedHandoffTarget]) -> [CappedHandoffTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedHandoffTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedHandoffTargets(_ store: any CappedHandoffTargetStore, query: CappedHandoffTargetQuery) -> [CappedHandoffTarget] {
        return query.apply(store.list())
    }
}
