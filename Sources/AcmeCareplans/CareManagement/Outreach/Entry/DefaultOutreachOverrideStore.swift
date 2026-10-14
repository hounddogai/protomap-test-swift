import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default outreach overrides by code.
    protocol DefaultOutreachOverrideStore {
        func find(_ code: String) -> DefaultOutreachOverride?
        func save(_ item: DefaultOutreachOverride)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultOutreachOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultOutreachOverrideStore: DefaultOutreachOverrideStore {
        var items: [String: DefaultOutreachOverride]
        var order: [String]

        init(items: [String: DefaultOutreachOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultOutreachOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultOutreachOverride) {
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

        func list() -> [DefaultOutreachOverride] {
            var out: [DefaultOutreachOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultOutreachOverrideStore() -> any DefaultOutreachOverrideStore {
        return MemoryDefaultOutreachOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultOutreachOverrideStore: DefaultOutreachOverrideStore {
        var inner: MemoryDefaultOutreachOverrideStore
        var cache: TTLCache<DefaultOutreachOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultOutreachOverrideStore, cache: TTLCache<DefaultOutreachOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultOutreachOverride? {
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

        func save(_ item: DefaultOutreachOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultOutreachOverride] {
            return inner.list()
        }
    }

    static func newCachedDefaultOutreachOverrideStore(_ inner: MemoryDefaultOutreachOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultOutreachOverrideStore {
        return CachedDefaultOutreachOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default outreach overrides. Empty fields match all.
    final class DefaultOutreachOverrideQuery {
        var segment: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minBudget: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultOutreachOverride) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [DefaultOutreachOverride]) -> [DefaultOutreachOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultOutreachOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultOutreachOverrides(_ store: any DefaultOutreachOverrideStore, query: DefaultOutreachOverrideQuery) -> [DefaultOutreachOverride] {
        return query.apply(store.list())
    }
}
