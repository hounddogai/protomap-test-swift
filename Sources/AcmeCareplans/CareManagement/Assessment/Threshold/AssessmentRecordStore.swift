import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment records by code.
    protocol AssessmentRecordStore {
        func find(_ code: String) -> AssessmentRecord?
        func save(_ item: AssessmentRecord)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentRecordStore: AssessmentRecordStore {
        var items: [String: AssessmentRecord]
        var order: [String]

        init(items: [String: AssessmentRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentRecord) {
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

        func list() -> [AssessmentRecord] {
            var out: [AssessmentRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentRecordStore() -> any AssessmentRecordStore {
        return MemoryAssessmentRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentRecordStore: AssessmentRecordStore {
        var inner: MemoryAssessmentRecordStore
        var cache: TTLCache<AssessmentRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentRecordStore, cache: TTLCache<AssessmentRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentRecord? {
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

        func save(_ item: AssessmentRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentRecord] {
            return inner.list()
        }
    }

    static func newCachedAssessmentRecordStore(_ inner: MemoryAssessmentRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentRecordStore {
        return CachedAssessmentRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment records. Empty fields match all.
    final class AssessmentRecordQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentRecord]) -> [AssessmentRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentRecords(_ store: any AssessmentRecordStore, query: AssessmentRecordQuery) -> [AssessmentRecord] {
        return query.apply(store.list())
    }
}
