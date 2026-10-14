import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result records by code.
    protocol ResultRecordStore {
        func find(_ code: String) -> ResultRecord?
        func save(_ item: ResultRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ResultRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultRecordStore: ResultRecordStore {
        var items: [String: ResultRecord]
        var order: [String]

        init(items: [String: ResultRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultRecord) {
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

        func list() -> [ResultRecord] {
            var out: [ResultRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultRecordStore() -> any ResultRecordStore {
        return MemoryResultRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultRecordStore: ResultRecordStore {
        var inner: MemoryResultRecordStore
        var cache: TTLCache<ResultRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultRecordStore, cache: TTLCache<ResultRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultRecord? {
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

        func save(_ item: ResultRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultRecord] {
            return inner.list()
        }
    }

    static func newCachedResultRecordStore(_ inner: MemoryResultRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultRecordStore {
        return CachedResultRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result records. Empty fields match all.
    final class ResultRecordQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultRecord]) -> [ResultRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultRecords(_ store: any ResultRecordStore, query: ResultRecordQuery) -> [ResultRecord] {
        return query.apply(store.list())
    }
}
