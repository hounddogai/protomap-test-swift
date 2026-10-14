import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default float pool assignments by code.
    protocol DefaultFloatPoolAssignmentStore {
        func find(_ code: String) -> DefaultFloatPoolAssignment?
        func save(_ item: DefaultFloatPoolAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultFloatPoolAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultFloatPoolAssignmentStore: DefaultFloatPoolAssignmentStore {
        var items: [String: DefaultFloatPoolAssignment]
        var order: [String]

        init(items: [String: DefaultFloatPoolAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultFloatPoolAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultFloatPoolAssignment) {
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

        func list() -> [DefaultFloatPoolAssignment] {
            var out: [DefaultFloatPoolAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultFloatPoolAssignmentStore() -> any DefaultFloatPoolAssignmentStore {
        return MemoryDefaultFloatPoolAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultFloatPoolAssignmentStore: DefaultFloatPoolAssignmentStore {
        var inner: MemoryDefaultFloatPoolAssignmentStore
        var cache: TTLCache<DefaultFloatPoolAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultFloatPoolAssignmentStore, cache: TTLCache<DefaultFloatPoolAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultFloatPoolAssignment? {
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

        func save(_ item: DefaultFloatPoolAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultFloatPoolAssignment] {
            return inner.list()
        }
    }

    static func newCachedDefaultFloatPoolAssignmentStore(_ inner: MemoryDefaultFloatPoolAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultFloatPoolAssignmentStore {
        return CachedDefaultFloatPoolAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default float pool assignments. Empty fields match all.
    final class DefaultFloatPoolAssignmentQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultFloatPoolAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultFloatPoolAssignment]) -> [DefaultFloatPoolAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultFloatPoolAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultFloatPoolAssignments(_ store: any DefaultFloatPoolAssignmentStore, query: DefaultFloatPoolAssignmentQuery) -> [DefaultFloatPoolAssignment] {
        return query.apply(store.list())
    }
}
