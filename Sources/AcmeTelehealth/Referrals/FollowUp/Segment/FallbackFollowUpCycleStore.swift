import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback follow up cycles by code.
    protocol FallbackFollowUpCycleStore {
        func find(_ code: String) -> FallbackFollowUpCycle?
        func save(_ item: FallbackFollowUpCycle)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackFollowUpCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackFollowUpCycleStore: FallbackFollowUpCycleStore {
        var items: [String: FallbackFollowUpCycle]
        var order: [String]

        init(items: [String: FallbackFollowUpCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackFollowUpCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackFollowUpCycle) {
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

        func list() -> [FallbackFollowUpCycle] {
            var out: [FallbackFollowUpCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackFollowUpCycleStore() -> any FallbackFollowUpCycleStore {
        return MemoryFallbackFollowUpCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackFollowUpCycleStore: FallbackFollowUpCycleStore {
        var inner: MemoryFallbackFollowUpCycleStore
        var cache: TTLCache<FallbackFollowUpCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackFollowUpCycleStore, cache: TTLCache<FallbackFollowUpCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackFollowUpCycle? {
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

        func save(_ item: FallbackFollowUpCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackFollowUpCycle] {
            return inner.list()
        }
    }

    static func newCachedFallbackFollowUpCycleStore(_ inner: MemoryFallbackFollowUpCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackFollowUpCycleStore {
        return CachedFallbackFollowUpCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback follow up cycles. Empty fields match all.
    final class FallbackFollowUpCycleQuery {
        var region: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackFollowUpCycle) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackFollowUpCycle]) -> [FallbackFollowUpCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackFollowUpCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackFollowUpCycles(_ store: any FallbackFollowUpCycleStore, query: FallbackFollowUpCycleQuery) -> [FallbackFollowUpCycle] {
        return query.apply(store.list())
    }
}
