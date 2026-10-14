import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary language assignments by code.
    protocol PrimaryLanguageAssignmentStore {
        func find(_ code: String) -> PrimaryLanguageAssignment?
        func save(_ item: PrimaryLanguageAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryLanguageAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryLanguageAssignmentStore: PrimaryLanguageAssignmentStore {
        var items: [String: PrimaryLanguageAssignment]
        var order: [String]

        init(items: [String: PrimaryLanguageAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryLanguageAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryLanguageAssignment) {
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

        func list() -> [PrimaryLanguageAssignment] {
            var out: [PrimaryLanguageAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryLanguageAssignmentStore() -> any PrimaryLanguageAssignmentStore {
        return MemoryPrimaryLanguageAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryLanguageAssignmentStore: PrimaryLanguageAssignmentStore {
        var inner: MemoryPrimaryLanguageAssignmentStore
        var cache: TTLCache<PrimaryLanguageAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryLanguageAssignmentStore, cache: TTLCache<PrimaryLanguageAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryLanguageAssignment? {
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

        func save(_ item: PrimaryLanguageAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryLanguageAssignment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryLanguageAssignmentStore(_ inner: MemoryPrimaryLanguageAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryLanguageAssignmentStore {
        return CachedPrimaryLanguageAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary language assignments. Empty fields match all.
    final class PrimaryLanguageAssignmentQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryLanguageAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryLanguageAssignment]) -> [PrimaryLanguageAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryLanguageAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryLanguageAssignments(_ store: any PrimaryLanguageAssignmentStore, query: PrimaryLanguageAssignmentQuery) -> [PrimaryLanguageAssignment] {
        return query.apply(store.list())
    }
}
