import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study groups by code.
    protocol StudyGroupStore {
        func find(_ code: String) -> StudyGroup?
        func save(_ item: StudyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [StudyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyGroupStore: StudyGroupStore {
        var items: [String: StudyGroup]
        var order: [String]

        init(items: [String: StudyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyGroup) {
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

        func list() -> [StudyGroup] {
            var out: [StudyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyGroupStore() -> any StudyGroupStore {
        return MemoryStudyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyGroupStore: StudyGroupStore {
        var inner: MemoryStudyGroupStore
        var cache: TTLCache<StudyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyGroupStore, cache: TTLCache<StudyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyGroup? {
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

        func save(_ item: StudyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyGroup] {
            return inner.list()
        }
    }

    static func newCachedStudyGroupStore(_ inner: MemoryStudyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyGroupStore {
        return CachedStudyGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study groups. Empty fields match all.
    final class StudyGroupQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyGroup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyGroup]) -> [StudyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyGroups(_ store: any StudyGroupStore, query: StudyGroupQuery) -> [StudyGroup] {
        return query.apply(store.list())
    }
}
