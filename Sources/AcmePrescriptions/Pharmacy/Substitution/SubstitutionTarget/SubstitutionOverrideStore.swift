import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution overrides by code.
    protocol SubstitutionOverrideStore {
        func find(_ code: String) -> SubstitutionOverride?
        func save(_ item: SubstitutionOverride)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionOverrideStore: SubstitutionOverrideStore {
        var items: [String: SubstitutionOverride]
        var order: [String]

        init(items: [String: SubstitutionOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionOverride) {
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

        func list() -> [SubstitutionOverride] {
            var out: [SubstitutionOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionOverrideStore() -> any SubstitutionOverrideStore {
        return MemorySubstitutionOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionOverrideStore: SubstitutionOverrideStore {
        var inner: MemorySubstitutionOverrideStore
        var cache: TTLCache<SubstitutionOverride>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionOverrideStore, cache: TTLCache<SubstitutionOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionOverride? {
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

        func save(_ item: SubstitutionOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionOverride] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionOverrideStore(_ inner: MemorySubstitutionOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionOverrideStore {
        return CachedSubstitutionOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution overrides. Empty fields match all.
    final class SubstitutionOverrideQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionOverride) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionOverride]) -> [SubstitutionOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionOverrides(_ store: any SubstitutionOverrideStore, query: SubstitutionOverrideQuery) -> [SubstitutionOverride] {
        return query.apply(store.list())
    }
}
