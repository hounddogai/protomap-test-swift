import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study baselines by code.
    protocol StudyBaselineStore {
        func find(_ code: String) -> StudyBaseline?
        func save(_ item: StudyBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [StudyBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyBaselineStore: StudyBaselineStore {
        var items: [String: StudyBaseline]
        var order: [String]

        init(items: [String: StudyBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyBaseline) {
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

        func list() -> [StudyBaseline] {
            var out: [StudyBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyBaselineStore() -> any StudyBaselineStore {
        return MemoryStudyBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyBaselineStore: StudyBaselineStore {
        var inner: MemoryStudyBaselineStore
        var cache: TTLCache<StudyBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyBaselineStore, cache: TTLCache<StudyBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyBaseline? {
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

        func save(_ item: StudyBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyBaseline] {
            return inner.list()
        }
    }

    static func newCachedStudyBaselineStore(_ inner: MemoryStudyBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyBaselineStore {
        return CachedStudyBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study baselines. Empty fields match all.
    final class StudyBaselineQuery {
        var ward: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRate: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyBaseline]) -> [StudyBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyBaselines(_ store: any StudyBaselineStore, query: StudyBaselineQuery) -> [StudyBaseline] {
        return query.apply(store.list())
    }
}
