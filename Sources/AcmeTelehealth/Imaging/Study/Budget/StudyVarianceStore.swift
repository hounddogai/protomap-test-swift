import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study variances by code.
    protocol StudyVarianceStore {
        func find(_ code: String) -> StudyVariance?
        func save(_ item: StudyVariance)
        func remove(_ code: String) -> Bool
        func list() -> [StudyVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyVarianceStore: StudyVarianceStore {
        var items: [String: StudyVariance]
        var order: [String]

        init(items: [String: StudyVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyVariance) {
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

        func list() -> [StudyVariance] {
            var out: [StudyVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyVarianceStore() -> any StudyVarianceStore {
        return MemoryStudyVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyVarianceStore: StudyVarianceStore {
        var inner: MemoryStudyVarianceStore
        var cache: TTLCache<StudyVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyVarianceStore, cache: TTLCache<StudyVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyVariance? {
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

        func save(_ item: StudyVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyVariance] {
            return inner.list()
        }
    }

    static func newCachedStudyVarianceStore(_ inner: MemoryStudyVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyVarianceStore {
        return CachedStudyVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study variances. Empty fields match all.
    final class StudyVarianceQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyVariance]) -> [StudyVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyVariances(_ store: any StudyVarianceStore, query: StudyVarianceQuery) -> [StudyVariance] {
        return query.apply(store.list())
    }
}
