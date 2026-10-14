import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual outreach records by code.
    protocol ManualOutreachRecordStore {
        func find(_ code: String) -> ManualOutreachRecord?
        func save(_ item: ManualOutreachRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOutreachRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOutreachRecordStore: ManualOutreachRecordStore {
        var items: [String: ManualOutreachRecord]
        var order: [String]

        init(items: [String: ManualOutreachRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOutreachRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOutreachRecord) {
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

        func list() -> [ManualOutreachRecord] {
            var out: [ManualOutreachRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOutreachRecordStore() -> any ManualOutreachRecordStore {
        return MemoryManualOutreachRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOutreachRecordStore: ManualOutreachRecordStore {
        var inner: MemoryManualOutreachRecordStore
        var cache: TTLCache<ManualOutreachRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOutreachRecordStore, cache: TTLCache<ManualOutreachRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOutreachRecord? {
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

        func save(_ item: ManualOutreachRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOutreachRecord] {
            return inner.list()
        }
    }

    static func newCachedManualOutreachRecordStore(_ inner: MemoryManualOutreachRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOutreachRecordStore {
        return CachedManualOutreachRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual outreach records. Empty fields match all.
    final class ManualOutreachRecordQuery {
        var category: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minScore: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOutreachRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ManualOutreachRecord]) -> [ManualOutreachRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOutreachRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOutreachRecords(_ store: any ManualOutreachRecordStore, query: ManualOutreachRecordQuery) -> [ManualOutreachRecord] {
        return query.apply(store.list())
    }
}
