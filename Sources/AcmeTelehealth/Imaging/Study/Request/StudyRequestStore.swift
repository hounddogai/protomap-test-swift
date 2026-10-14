import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study requests by code.
    protocol StudyRequestStore {
        func find(_ code: String) -> StudyRequest?
        func save(_ item: StudyRequest)
        func remove(_ code: String) -> Bool
        func list() -> [StudyRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyRequestStore: StudyRequestStore {
        var items: [String: StudyRequest]
        var order: [String]

        init(items: [String: StudyRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyRequest) {
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

        func list() -> [StudyRequest] {
            var out: [StudyRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyRequestStore() -> any StudyRequestStore {
        return MemoryStudyRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyRequestStore: StudyRequestStore {
        var inner: MemoryStudyRequestStore
        var cache: TTLCache<StudyRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyRequestStore, cache: TTLCache<StudyRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyRequest? {
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

        func save(_ item: StudyRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyRequest] {
            return inner.list()
        }
    }

    static func newCachedStudyRequestStore(_ inner: MemoryStudyRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyRequestStore {
        return CachedStudyRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study requests. Empty fields match all.
    final class StudyRequestQuery {
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

        func matches(_ item: StudyRequest) -> Bool {
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

        func apply(_ items: [StudyRequest]) -> [StudyRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyRequests(_ store: any StudyRequestStore, query: StudyRequestQuery) -> [StudyRequest] {
        return query.apply(store.list())
    }
}
