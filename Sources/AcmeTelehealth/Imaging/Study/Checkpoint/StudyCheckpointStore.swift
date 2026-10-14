import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study checkpoints by code.
    protocol StudyCheckpointStore {
        func find(_ code: String) -> StudyCheckpoint?
        func save(_ item: StudyCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [StudyCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyCheckpointStore: StudyCheckpointStore {
        var items: [String: StudyCheckpoint]
        var order: [String]

        init(items: [String: StudyCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyCheckpoint) {
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

        func list() -> [StudyCheckpoint] {
            var out: [StudyCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyCheckpointStore() -> any StudyCheckpointStore {
        return MemoryStudyCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyCheckpointStore: StudyCheckpointStore {
        var inner: MemoryStudyCheckpointStore
        var cache: TTLCache<StudyCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyCheckpointStore, cache: TTLCache<StudyCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyCheckpoint? {
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

        func save(_ item: StudyCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedStudyCheckpointStore(_ inner: MemoryStudyCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyCheckpointStore {
        return CachedStudyCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study checkpoints. Empty fields match all.
    final class StudyCheckpointQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyCheckpoint) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [StudyCheckpoint]) -> [StudyCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyCheckpoints(_ store: any StudyCheckpointStore, query: StudyCheckpointQuery) -> [StudyCheckpoint] {
        return query.apply(store.list())
    }
}
