import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study snapshots by code.
    protocol StudySnapshotStore {
        func find(_ code: String) -> StudySnapshot?
        func save(_ item: StudySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [StudySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudySnapshotStore: StudySnapshotStore {
        var items: [String: StudySnapshot]
        var order: [String]

        init(items: [String: StudySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudySnapshot) {
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

        func list() -> [StudySnapshot] {
            var out: [StudySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudySnapshotStore() -> any StudySnapshotStore {
        return MemoryStudySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudySnapshotStore: StudySnapshotStore {
        var inner: MemoryStudySnapshotStore
        var cache: TTLCache<StudySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudySnapshotStore, cache: TTLCache<StudySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudySnapshot? {
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

        func save(_ item: StudySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudySnapshot] {
            return inner.list()
        }
    }

    static func newCachedStudySnapshotStore(_ inner: MemoryStudySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudySnapshotStore {
        return CachedStudySnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study snapshots. Empty fields match all.
    final class StudySnapshotQuery {
        var source: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudySnapshot) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [StudySnapshot]) -> [StudySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudySnapshots(_ store: any StudySnapshotStore, query: StudySnapshotQuery) -> [StudySnapshot] {
        return query.apply(store.list())
    }
}
