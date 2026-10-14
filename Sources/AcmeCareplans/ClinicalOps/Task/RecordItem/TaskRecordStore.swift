import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task records by code.
    protocol TaskRecordStore {
        func find(_ code: String) -> TaskRecord?
        func save(_ item: TaskRecord)
        func remove(_ code: String) -> Bool
        func list() -> [TaskRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskRecordStore: TaskRecordStore {
        var items: [String: TaskRecord]
        var order: [String]

        init(items: [String: TaskRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskRecord) {
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

        func list() -> [TaskRecord] {
            var out: [TaskRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskRecordStore() -> any TaskRecordStore {
        return MemoryTaskRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskRecordStore: TaskRecordStore {
        var inner: MemoryTaskRecordStore
        var cache: TTLCache<TaskRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskRecordStore, cache: TTLCache<TaskRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskRecord? {
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

        func save(_ item: TaskRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskRecord] {
            return inner.list()
        }
    }

    static func newCachedTaskRecordStore(_ inner: MemoryTaskRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskRecordStore {
        return CachedTaskRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task records. Empty fields match all.
    final class TaskRecordQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskRecord) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskRecord]) -> [TaskRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskRecords(_ store: any TaskRecordStore, query: TaskRecordQuery) -> [TaskRecord] {
        return query.apply(store.list())
    }
}
