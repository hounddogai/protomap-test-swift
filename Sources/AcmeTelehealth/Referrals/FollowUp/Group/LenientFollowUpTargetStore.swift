import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient follow up targets by code.
    protocol LenientFollowUpTargetStore {
        func find(_ code: String) -> LenientFollowUpTarget?
        func save(_ item: LenientFollowUpTarget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientFollowUpTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientFollowUpTargetStore: LenientFollowUpTargetStore {
        var items: [String: LenientFollowUpTarget]
        var order: [String]

        init(items: [String: LenientFollowUpTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientFollowUpTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientFollowUpTarget) {
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

        func list() -> [LenientFollowUpTarget] {
            var out: [LenientFollowUpTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientFollowUpTargetStore() -> any LenientFollowUpTargetStore {
        return MemoryLenientFollowUpTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientFollowUpTargetStore: LenientFollowUpTargetStore {
        var inner: MemoryLenientFollowUpTargetStore
        var cache: TTLCache<LenientFollowUpTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientFollowUpTargetStore, cache: TTLCache<LenientFollowUpTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientFollowUpTarget? {
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

        func save(_ item: LenientFollowUpTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientFollowUpTarget] {
            return inner.list()
        }
    }

    static func newCachedLenientFollowUpTargetStore(_ inner: MemoryLenientFollowUpTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientFollowUpTargetStore {
        return CachedLenientFollowUpTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient follow up targets. Empty fields match all.
    final class LenientFollowUpTargetQuery {
        var source: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientFollowUpTarget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientFollowUpTarget]) -> [LenientFollowUpTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientFollowUpTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientFollowUpTargets(_ store: any LenientFollowUpTargetStore, query: LenientFollowUpTargetQuery) -> [LenientFollowUpTarget] {
        return query.apply(store.list())
    }
}
