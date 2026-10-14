import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global goal records by code.
    protocol GlobalGoalRecordStore {
        func find(_ code: String) -> GlobalGoalRecord?
        func save(_ item: GlobalGoalRecord)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalGoalRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalGoalRecordStore: GlobalGoalRecordStore {
        var items: [String: GlobalGoalRecord]
        var order: [String]

        init(items: [String: GlobalGoalRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalGoalRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalGoalRecord) {
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

        func list() -> [GlobalGoalRecord] {
            var out: [GlobalGoalRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalGoalRecordStore() -> any GlobalGoalRecordStore {
        return MemoryGlobalGoalRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalGoalRecordStore: GlobalGoalRecordStore {
        var inner: MemoryGlobalGoalRecordStore
        var cache: TTLCache<GlobalGoalRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalGoalRecordStore, cache: TTLCache<GlobalGoalRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalGoalRecord? {
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

        func save(_ item: GlobalGoalRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalGoalRecord] {
            return inner.list()
        }
    }

    static func newCachedGlobalGoalRecordStore(_ inner: MemoryGlobalGoalRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalGoalRecordStore {
        return CachedGlobalGoalRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global goal records. Empty fields match all.
    final class GlobalGoalRecordQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalGoalRecord) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalGoalRecord]) -> [GlobalGoalRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalGoalRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalGoalRecords(_ store: any GlobalGoalRecordStore, query: GlobalGoalRecordQuery) -> [GlobalGoalRecord] {
        return query.apply(store.list())
    }
}
