import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled care protocol thresholds by code.
    protocol ScheduledCareProtocolThresholdStore {
        func find(_ code: String) -> ScheduledCareProtocolThreshold?
        func save(_ item: ScheduledCareProtocolThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolThresholdStore: ScheduledCareProtocolThresholdStore {
        var items: [String: ScheduledCareProtocolThreshold]
        var order: [String]

        init(items: [String: ScheduledCareProtocolThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolThreshold) {
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

        func list() -> [ScheduledCareProtocolThreshold] {
            var out: [ScheduledCareProtocolThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolThresholdStore() -> any ScheduledCareProtocolThresholdStore {
        return MemoryScheduledCareProtocolThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolThresholdStore: ScheduledCareProtocolThresholdStore {
        var inner: MemoryScheduledCareProtocolThresholdStore
        var cache: TTLCache<ScheduledCareProtocolThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolThresholdStore, cache: TTLCache<ScheduledCareProtocolThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolThreshold? {
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

        func save(_ item: ScheduledCareProtocolThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolThreshold] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolThresholdStore(_ inner: MemoryScheduledCareProtocolThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolThresholdStore {
        return CachedScheduledCareProtocolThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol thresholds. Empty fields match all.
    final class ScheduledCareProtocolThresholdQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolThreshold) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ScheduledCareProtocolThreshold]) -> [ScheduledCareProtocolThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolThresholds(_ store: any ScheduledCareProtocolThresholdStore, query: ScheduledCareProtocolThresholdQuery) -> [ScheduledCareProtocolThreshold] {
        return query.apply(store.list())
    }
}
