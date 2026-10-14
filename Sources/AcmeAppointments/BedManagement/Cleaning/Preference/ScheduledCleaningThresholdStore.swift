import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled cleaning thresholds by code.
    protocol ScheduledCleaningThresholdStore {
        func find(_ code: String) -> ScheduledCleaningThreshold?
        func save(_ item: ScheduledCleaningThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCleaningThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCleaningThresholdStore: ScheduledCleaningThresholdStore {
        var items: [String: ScheduledCleaningThreshold]
        var order: [String]

        init(items: [String: ScheduledCleaningThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCleaningThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCleaningThreshold) {
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

        func list() -> [ScheduledCleaningThreshold] {
            var out: [ScheduledCleaningThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCleaningThresholdStore() -> any ScheduledCleaningThresholdStore {
        return MemoryScheduledCleaningThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCleaningThresholdStore: ScheduledCleaningThresholdStore {
        var inner: MemoryScheduledCleaningThresholdStore
        var cache: TTLCache<ScheduledCleaningThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCleaningThresholdStore, cache: TTLCache<ScheduledCleaningThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCleaningThreshold? {
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

        func save(_ item: ScheduledCleaningThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCleaningThreshold] {
            return inner.list()
        }
    }

    static func newCachedScheduledCleaningThresholdStore(_ inner: MemoryScheduledCleaningThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCleaningThresholdStore {
        return CachedScheduledCleaningThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled cleaning thresholds. Empty fields match all.
    final class ScheduledCleaningThresholdQuery {
        var segment: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minScore: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCleaningThreshold) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCleaningThreshold]) -> [ScheduledCleaningThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCleaningThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCleaningThresholds(_ store: any ScheduledCleaningThresholdStore, query: ScheduledCleaningThresholdQuery) -> [ScheduledCleaningThreshold] {
        return query.apply(store.list())
    }
}
