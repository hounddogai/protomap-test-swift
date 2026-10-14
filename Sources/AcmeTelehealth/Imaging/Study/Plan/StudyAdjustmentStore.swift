import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study adjustments by code.
    protocol StudyAdjustmentStore {
        func find(_ code: String) -> StudyAdjustment?
        func save(_ item: StudyAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [StudyAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyAdjustmentStore: StudyAdjustmentStore {
        var items: [String: StudyAdjustment]
        var order: [String]

        init(items: [String: StudyAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyAdjustment) {
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

        func list() -> [StudyAdjustment] {
            var out: [StudyAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyAdjustmentStore() -> any StudyAdjustmentStore {
        return MemoryStudyAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyAdjustmentStore: StudyAdjustmentStore {
        var inner: MemoryStudyAdjustmentStore
        var cache: TTLCache<StudyAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyAdjustmentStore, cache: TTLCache<StudyAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyAdjustment? {
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

        func save(_ item: StudyAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyAdjustment] {
            return inner.list()
        }
    }

    static func newCachedStudyAdjustmentStore(_ inner: MemoryStudyAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyAdjustmentStore {
        return CachedStudyAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study adjustments. Empty fields match all.
    final class StudyAdjustmentQuery {
        var source: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMargin: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyAdjustment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyAdjustment]) -> [StudyAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyAdjustments(_ store: any StudyAdjustmentStore, query: StudyAdjustmentQuery) -> [StudyAdjustment] {
        return query.apply(store.list())
    }
}
