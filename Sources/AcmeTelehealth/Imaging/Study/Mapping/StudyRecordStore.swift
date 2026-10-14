import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study records by code.
    protocol StudyRecordStore {
        func find(_ code: String) -> StudyRecord?
        func save(_ item: StudyRecord)
        func remove(_ code: String) -> Bool
        func list() -> [StudyRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyRecordStore: StudyRecordStore {
        var items: [String: StudyRecord]
        var order: [String]

        init(items: [String: StudyRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyRecord) {
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

        func list() -> [StudyRecord] {
            var out: [StudyRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyRecordStore() -> any StudyRecordStore {
        return MemoryStudyRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyRecordStore: StudyRecordStore {
        var inner: MemoryStudyRecordStore
        var cache: TTLCache<StudyRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyRecordStore, cache: TTLCache<StudyRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyRecord? {
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

        func save(_ item: StudyRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyRecord] {
            return inner.list()
        }
    }

    static func newCachedStudyRecordStore(_ inner: MemoryStudyRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyRecordStore {
        return CachedStudyRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study records. Empty fields match all.
    final class StudyRecordQuery {
        var category: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyRecord]) -> [StudyRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyRecords(_ store: any StudyRecordStore, query: StudyRecordQuery) -> [StudyRecord] {
        return query.apply(store.list())
    }
}
