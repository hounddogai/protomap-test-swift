import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict assessment entries by code.
    protocol StrictAssessmentEntryStore {
        func find(_ code: String) -> StrictAssessmentEntry?
        func save(_ item: StrictAssessmentEntry)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAssessmentEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAssessmentEntryStore: StrictAssessmentEntryStore {
        var items: [String: StrictAssessmentEntry]
        var order: [String]

        init(items: [String: StrictAssessmentEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAssessmentEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAssessmentEntry) {
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

        func list() -> [StrictAssessmentEntry] {
            var out: [StrictAssessmentEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAssessmentEntryStore() -> any StrictAssessmentEntryStore {
        return MemoryStrictAssessmentEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAssessmentEntryStore: StrictAssessmentEntryStore {
        var inner: MemoryStrictAssessmentEntryStore
        var cache: TTLCache<StrictAssessmentEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAssessmentEntryStore, cache: TTLCache<StrictAssessmentEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAssessmentEntry? {
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

        func save(_ item: StrictAssessmentEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAssessmentEntry] {
            return inner.list()
        }
    }

    static func newCachedStrictAssessmentEntryStore(_ inner: MemoryStrictAssessmentEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAssessmentEntryStore {
        return CachedStrictAssessmentEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict assessment entries. Empty fields match all.
    final class StrictAssessmentEntryQuery {
        var category: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCopay: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAssessmentEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictAssessmentEntry]) -> [StrictAssessmentEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAssessmentEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAssessmentEntries(_ store: any StrictAssessmentEntryStore, query: StrictAssessmentEntryQuery) -> [StrictAssessmentEntry] {
        return query.apply(store.list())
    }
}
