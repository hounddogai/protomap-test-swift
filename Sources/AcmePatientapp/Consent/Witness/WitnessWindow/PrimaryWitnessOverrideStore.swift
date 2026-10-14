import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary witness overrides by code.
    protocol PrimaryWitnessOverrideStore {
        func find(_ code: String) -> PrimaryWitnessOverride?
        func save(_ item: PrimaryWitnessOverride)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryWitnessOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryWitnessOverrideStore: PrimaryWitnessOverrideStore {
        var items: [String: PrimaryWitnessOverride]
        var order: [String]

        init(items: [String: PrimaryWitnessOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryWitnessOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryWitnessOverride) {
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

        func list() -> [PrimaryWitnessOverride] {
            var out: [PrimaryWitnessOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryWitnessOverrideStore() -> any PrimaryWitnessOverrideStore {
        return MemoryPrimaryWitnessOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryWitnessOverrideStore: PrimaryWitnessOverrideStore {
        var inner: MemoryPrimaryWitnessOverrideStore
        var cache: TTLCache<PrimaryWitnessOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryWitnessOverrideStore, cache: TTLCache<PrimaryWitnessOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryWitnessOverride? {
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

        func save(_ item: PrimaryWitnessOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryWitnessOverride] {
            return inner.list()
        }
    }

    static func newCachedPrimaryWitnessOverrideStore(_ inner: MemoryPrimaryWitnessOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryWitnessOverrideStore {
        return CachedPrimaryWitnessOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary witness overrides. Empty fields match all.
    final class PrimaryWitnessOverrideQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryWitnessOverride) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryWitnessOverride]) -> [PrimaryWitnessOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryWitnessOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryWitnessOverrides(_ store: any PrimaryWitnessOverrideStore, query: PrimaryWitnessOverrideQuery) -> [PrimaryWitnessOverride] {
        return query.apply(store.list())
    }
}
