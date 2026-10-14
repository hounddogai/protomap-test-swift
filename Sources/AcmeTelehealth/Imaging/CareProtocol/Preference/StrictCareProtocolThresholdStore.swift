import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict care protocol thresholds by code.
    protocol StrictCareProtocolThresholdStore {
        func find(_ code: String) -> StrictCareProtocolThreshold?
        func save(_ item: StrictCareProtocolThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCareProtocolThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCareProtocolThresholdStore: StrictCareProtocolThresholdStore {
        var items: [String: StrictCareProtocolThreshold]
        var order: [String]

        init(items: [String: StrictCareProtocolThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCareProtocolThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCareProtocolThreshold) {
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

        func list() -> [StrictCareProtocolThreshold] {
            var out: [StrictCareProtocolThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCareProtocolThresholdStore() -> any StrictCareProtocolThresholdStore {
        return MemoryStrictCareProtocolThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCareProtocolThresholdStore: StrictCareProtocolThresholdStore {
        var inner: MemoryStrictCareProtocolThresholdStore
        var cache: TTLCache<StrictCareProtocolThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCareProtocolThresholdStore, cache: TTLCache<StrictCareProtocolThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCareProtocolThreshold? {
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

        func save(_ item: StrictCareProtocolThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCareProtocolThreshold] {
            return inner.list()
        }
    }

    static func newCachedStrictCareProtocolThresholdStore(_ inner: MemoryStrictCareProtocolThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCareProtocolThresholdStore {
        return CachedStrictCareProtocolThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict care protocol thresholds. Empty fields match all.
    final class StrictCareProtocolThresholdQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCareProtocolThreshold) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [StrictCareProtocolThreshold]) -> [StrictCareProtocolThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCareProtocolThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCareProtocolThresholds(_ store: any StrictCareProtocolThresholdStore, query: StrictCareProtocolThresholdQuery) -> [StrictCareProtocolThreshold] {
        return query.apply(store.list())
    }
}
