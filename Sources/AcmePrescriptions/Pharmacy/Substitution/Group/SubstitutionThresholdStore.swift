import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution thresholds by code.
    protocol SubstitutionThresholdStore {
        func find(_ code: String) -> SubstitutionThreshold?
        func save(_ item: SubstitutionThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionThresholdStore: SubstitutionThresholdStore {
        var items: [String: SubstitutionThreshold]
        var order: [String]

        init(items: [String: SubstitutionThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionThreshold) {
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

        func list() -> [SubstitutionThreshold] {
            var out: [SubstitutionThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionThresholdStore() -> any SubstitutionThresholdStore {
        return MemorySubstitutionThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionThresholdStore: SubstitutionThresholdStore {
        var inner: MemorySubstitutionThresholdStore
        var cache: TTLCache<SubstitutionThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionThresholdStore, cache: TTLCache<SubstitutionThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionThreshold? {
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

        func save(_ item: SubstitutionThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionThreshold] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionThresholdStore(_ inner: MemorySubstitutionThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionThresholdStore {
        return CachedSubstitutionThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution thresholds. Empty fields match all.
    final class SubstitutionThresholdQuery {
        var source: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [SubstitutionThreshold]) -> [SubstitutionThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionThresholds(_ store: any SubstitutionThresholdStore, query: SubstitutionThresholdQuery) -> [SubstitutionThreshold] {
        return query.apply(store.list())
    }
}
