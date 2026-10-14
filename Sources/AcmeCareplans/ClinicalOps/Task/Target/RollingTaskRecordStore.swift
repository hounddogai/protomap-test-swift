import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling task records by code.
    protocol RollingTaskRecordStore {
        func find(_ code: String) -> RollingTaskRecord?
        func save(_ item: RollingTaskRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RollingTaskRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingTaskRecordStore: RollingTaskRecordStore {
        var items: [String: RollingTaskRecord]
        var order: [String]

        init(items: [String: RollingTaskRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingTaskRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingTaskRecord) {
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

        func list() -> [RollingTaskRecord] {
            var out: [RollingTaskRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingTaskRecordStore() -> any RollingTaskRecordStore {
        return MemoryRollingTaskRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingTaskRecordStore: RollingTaskRecordStore {
        var inner: MemoryRollingTaskRecordStore
        var cache: TTLCache<RollingTaskRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingTaskRecordStore, cache: TTLCache<RollingTaskRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingTaskRecord? {
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

        func save(_ item: RollingTaskRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingTaskRecord] {
            return inner.list()
        }
    }

    static func newCachedRollingTaskRecordStore(_ inner: MemoryRollingTaskRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingTaskRecordStore {
        return CachedRollingTaskRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling task records. Empty fields match all.
    final class RollingTaskRecordQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingTaskRecord) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingTaskRecord]) -> [RollingTaskRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingTaskRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingTaskRecords(_ store: any RollingTaskRecordStore, query: RollingTaskRecordQuery) -> [RollingTaskRecord] {
        return query.apply(store.list())
    }
}
