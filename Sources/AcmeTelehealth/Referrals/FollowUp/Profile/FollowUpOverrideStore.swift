import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up overrides by code.
    protocol FollowUpOverrideStore {
        func find(_ code: String) -> FollowUpOverride?
        func save(_ item: FollowUpOverride)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpOverrideStore: FollowUpOverrideStore {
        var items: [String: FollowUpOverride]
        var order: [String]

        init(items: [String: FollowUpOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpOverride) {
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

        func list() -> [FollowUpOverride] {
            var out: [FollowUpOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpOverrideStore() -> any FollowUpOverrideStore {
        return MemoryFollowUpOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpOverrideStore: FollowUpOverrideStore {
        var inner: MemoryFollowUpOverrideStore
        var cache: TTLCache<FollowUpOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpOverrideStore, cache: TTLCache<FollowUpOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpOverride? {
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

        func save(_ item: FollowUpOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpOverride] {
            return inner.list()
        }
    }

    static func newCachedFollowUpOverrideStore(_ inner: MemoryFollowUpOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpOverrideStore {
        return CachedFollowUpOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up overrides. Empty fields match all.
    final class FollowUpOverrideQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpOverride]) -> [FollowUpOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpOverrides(_ store: any FollowUpOverrideStore, query: FollowUpOverrideQuery) -> [FollowUpOverride] {
        return query.apply(store.list())
    }
}
