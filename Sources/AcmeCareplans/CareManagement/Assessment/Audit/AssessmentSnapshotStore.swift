import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment snapshots by code.
    protocol AssessmentSnapshotStore {
        func find(_ code: String) -> AssessmentSnapshot?
        func save(_ item: AssessmentSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentSnapshotStore: AssessmentSnapshotStore {
        var items: [String: AssessmentSnapshot]
        var order: [String]

        init(items: [String: AssessmentSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentSnapshot) {
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

        func list() -> [AssessmentSnapshot] {
            var out: [AssessmentSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentSnapshotStore() -> any AssessmentSnapshotStore {
        return MemoryAssessmentSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentSnapshotStore: AssessmentSnapshotStore {
        var inner: MemoryAssessmentSnapshotStore
        var cache: TTLCache<AssessmentSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentSnapshotStore, cache: TTLCache<AssessmentSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentSnapshot? {
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

        func save(_ item: AssessmentSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentSnapshot] {
            return inner.list()
        }
    }

    static func newCachedAssessmentSnapshotStore(_ inner: MemoryAssessmentSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentSnapshotStore {
        return CachedAssessmentSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment snapshots. Empty fields match all.
    final class AssessmentSnapshotQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentSnapshot]) -> [AssessmentSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentSnapshots(_ store: any AssessmentSnapshotStore, query: AssessmentSnapshotQuery) -> [AssessmentSnapshot] {
        return query.apply(store.list())
    }
}
