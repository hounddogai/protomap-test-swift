import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default care gap assignments by code.
    protocol DefaultCareGapAssignmentStore {
        func find(_ code: String) -> DefaultCareGapAssignment?
        func save(_ item: DefaultCareGapAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareGapAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareGapAssignmentStore: DefaultCareGapAssignmentStore {
        var items: [String: DefaultCareGapAssignment]
        var order: [String]

        init(items: [String: DefaultCareGapAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareGapAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareGapAssignment) {
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

        func list() -> [DefaultCareGapAssignment] {
            var out: [DefaultCareGapAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareGapAssignmentStore() -> any DefaultCareGapAssignmentStore {
        return MemoryDefaultCareGapAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareGapAssignmentStore: DefaultCareGapAssignmentStore {
        var inner: MemoryDefaultCareGapAssignmentStore
        var cache: TTLCache<DefaultCareGapAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareGapAssignmentStore, cache: TTLCache<DefaultCareGapAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareGapAssignment? {
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

        func save(_ item: DefaultCareGapAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareGapAssignment] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareGapAssignmentStore(_ inner: MemoryDefaultCareGapAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareGapAssignmentStore {
        return CachedDefaultCareGapAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care gap assignments. Empty fields match all.
    final class DefaultCareGapAssignmentQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareGapAssignment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCareGapAssignment]) -> [DefaultCareGapAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareGapAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareGapAssignments(_ store: any DefaultCareGapAssignmentStore, query: DefaultCareGapAssignmentQuery) -> [DefaultCareGapAssignment] {
        return query.apply(store.list())
    }
}
