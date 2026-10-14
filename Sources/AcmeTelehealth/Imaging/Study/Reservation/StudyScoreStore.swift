import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study scores by code.
    protocol StudyScoreStore {
        func find(_ code: String) -> StudyScore?
        func save(_ item: StudyScore)
        func remove(_ code: String) -> Bool
        func list() -> [StudyScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyScoreStore: StudyScoreStore {
        var items: [String: StudyScore]
        var order: [String]

        init(items: [String: StudyScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyScore) {
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

        func list() -> [StudyScore] {
            var out: [StudyScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyScoreStore() -> any StudyScoreStore {
        return MemoryStudyScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyScoreStore: StudyScoreStore {
        var inner: MemoryStudyScoreStore
        var cache: TTLCache<StudyScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyScoreStore, cache: TTLCache<StudyScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyScore? {
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

        func save(_ item: StudyScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyScore] {
            return inner.list()
        }
    }

    static func newCachedStudyScoreStore(_ inner: MemoryStudyScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyScoreStore {
        return CachedStudyScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study scores. Empty fields match all.
    final class StudyScoreQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyScore]) -> [StudyScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyScores(_ store: any StudyScoreStore, query: StudyScoreQuery) -> [StudyScore] {
        return query.apply(store.list())
    }
}
