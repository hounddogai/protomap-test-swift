import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global witness overrides by code.
    protocol GlobalWitnessOverrideStore {
        func find(_ code: String) -> GlobalWitnessOverride?
        func save(_ item: GlobalWitnessOverride)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalWitnessOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalWitnessOverrideStore: GlobalWitnessOverrideStore {
        var items: [String: GlobalWitnessOverride]
        var order: [String]

        init(items: [String: GlobalWitnessOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalWitnessOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalWitnessOverride) {
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

        func list() -> [GlobalWitnessOverride] {
            var out: [GlobalWitnessOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalWitnessOverrideStore() -> any GlobalWitnessOverrideStore {
        return MemoryGlobalWitnessOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalWitnessOverrideStore: GlobalWitnessOverrideStore {
        var inner: MemoryGlobalWitnessOverrideStore
        var cache: TTLCache<GlobalWitnessOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalWitnessOverrideStore, cache: TTLCache<GlobalWitnessOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalWitnessOverride? {
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

        func save(_ item: GlobalWitnessOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalWitnessOverride] {
            return inner.list()
        }
    }

    static func newCachedGlobalWitnessOverrideStore(_ inner: MemoryGlobalWitnessOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalWitnessOverrideStore {
        return CachedGlobalWitnessOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global witness overrides. Empty fields match all.
    final class GlobalWitnessOverrideQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalWitnessOverride) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalWitnessOverride]) -> [GlobalWitnessOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalWitnessOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalWitnessOverrides(_ store: any GlobalWitnessOverrideStore, query: GlobalWitnessOverrideQuery) -> [GlobalWitnessOverride] {
        return query.apply(store.list())
    }
}
