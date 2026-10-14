import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending follow up overrides by code.
    protocol PendingFollowUpOverrideStore {
        func find(_ code: String) -> PendingFollowUpOverride?
        func save(_ item: PendingFollowUpOverride)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFollowUpOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFollowUpOverrideStore: PendingFollowUpOverrideStore {
        var items: [String: PendingFollowUpOverride]
        var order: [String]

        init(items: [String: PendingFollowUpOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFollowUpOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFollowUpOverride) {
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

        func list() -> [PendingFollowUpOverride] {
            var out: [PendingFollowUpOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFollowUpOverrideStore() -> any PendingFollowUpOverrideStore {
        return MemoryPendingFollowUpOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFollowUpOverrideStore: PendingFollowUpOverrideStore {
        var inner: MemoryPendingFollowUpOverrideStore
        var cache: TTLCache<PendingFollowUpOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFollowUpOverrideStore, cache: TTLCache<PendingFollowUpOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFollowUpOverride? {
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

        func save(_ item: PendingFollowUpOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFollowUpOverride] {
            return inner.list()
        }
    }

    static func newCachedPendingFollowUpOverrideStore(_ inner: MemoryPendingFollowUpOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFollowUpOverrideStore {
        return CachedPendingFollowUpOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending follow up overrides. Empty fields match all.
    final class PendingFollowUpOverrideQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFollowUpOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFollowUpOverride]) -> [PendingFollowUpOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFollowUpOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFollowUpOverrides(_ store: any PendingFollowUpOverrideStore, query: PendingFollowUpOverrideQuery) -> [PendingFollowUpOverride] {
        return query.apply(store.list())
    }
}
