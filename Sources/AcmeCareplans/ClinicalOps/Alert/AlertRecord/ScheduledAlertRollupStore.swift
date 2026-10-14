import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled alert rollups by code.
    protocol ScheduledAlertRollupStore {
        func find(_ code: String) -> ScheduledAlertRollup?
        func save(_ item: ScheduledAlertRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAlertRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAlertRollupStore: ScheduledAlertRollupStore {
        var items: [String: ScheduledAlertRollup]
        var order: [String]

        init(items: [String: ScheduledAlertRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAlertRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAlertRollup) {
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

        func list() -> [ScheduledAlertRollup] {
            var out: [ScheduledAlertRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAlertRollupStore() -> any ScheduledAlertRollupStore {
        return MemoryScheduledAlertRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAlertRollupStore: ScheduledAlertRollupStore {
        var inner: MemoryScheduledAlertRollupStore
        var cache: TTLCache<ScheduledAlertRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAlertRollupStore, cache: TTLCache<ScheduledAlertRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAlertRollup? {
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

        func save(_ item: ScheduledAlertRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAlertRollup] {
            return inner.list()
        }
    }

    static func newCachedScheduledAlertRollupStore(_ inner: MemoryScheduledAlertRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAlertRollupStore {
        return CachedScheduledAlertRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled alert rollups. Empty fields match all.
    final class ScheduledAlertRollupQuery {
        var ward: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAlertRollup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ScheduledAlertRollup]) -> [ScheduledAlertRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAlertRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAlertRollups(_ store: any ScheduledAlertRollupStore, query: ScheduledAlertRollupQuery) -> [ScheduledAlertRollup] {
        return query.apply(store.list())
    }
}
