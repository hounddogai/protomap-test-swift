import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime rollups by code.
    protocol OvertimeRollupStore {
        func find(_ code: String) -> OvertimeRollup?
        func save(_ item: OvertimeRollup)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeRollupStore: OvertimeRollupStore {
        var items: [String: OvertimeRollup]
        var order: [String]

        init(items: [String: OvertimeRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeRollup) {
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

        func list() -> [OvertimeRollup] {
            var out: [OvertimeRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeRollupStore() -> any OvertimeRollupStore {
        return MemoryOvertimeRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeRollupStore: OvertimeRollupStore {
        var inner: MemoryOvertimeRollupStore
        var cache: TTLCache<OvertimeRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeRollupStore, cache: TTLCache<OvertimeRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeRollup? {
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

        func save(_ item: OvertimeRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeRollup] {
            return inner.list()
        }
    }

    static func newCachedOvertimeRollupStore(_ inner: MemoryOvertimeRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeRollupStore {
        return CachedOvertimeRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime rollups. Empty fields match all.
    final class OvertimeRollupQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeRollup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeRollup]) -> [OvertimeRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeRollups(_ store: any OvertimeRollupStore, query: OvertimeRollupQuery) -> [OvertimeRollup] {
        return query.apply(store.list())
    }
}
