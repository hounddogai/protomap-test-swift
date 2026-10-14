import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global care protocol assignments by code.
    protocol GlobalCareProtocolAssignmentStore {
        func find(_ code: String) -> GlobalCareProtocolAssignment?
        func save(_ item: GlobalCareProtocolAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareProtocolAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareProtocolAssignmentStore: GlobalCareProtocolAssignmentStore {
        var items: [String: GlobalCareProtocolAssignment]
        var order: [String]

        init(items: [String: GlobalCareProtocolAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareProtocolAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareProtocolAssignment) {
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

        func list() -> [GlobalCareProtocolAssignment] {
            var out: [GlobalCareProtocolAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareProtocolAssignmentStore() -> any GlobalCareProtocolAssignmentStore {
        return MemoryGlobalCareProtocolAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareProtocolAssignmentStore: GlobalCareProtocolAssignmentStore {
        var inner: MemoryGlobalCareProtocolAssignmentStore
        var cache: TTLCache<GlobalCareProtocolAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareProtocolAssignmentStore, cache: TTLCache<GlobalCareProtocolAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareProtocolAssignment? {
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

        func save(_ item: GlobalCareProtocolAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareProtocolAssignment] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareProtocolAssignmentStore(_ inner: MemoryGlobalCareProtocolAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareProtocolAssignmentStore {
        return CachedGlobalCareProtocolAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care protocol assignments. Empty fields match all.
    final class GlobalCareProtocolAssignmentQuery {
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

        func matches(_ item: GlobalCareProtocolAssignment) -> Bool {
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

        func apply(_ items: [GlobalCareProtocolAssignment]) -> [GlobalCareProtocolAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareProtocolAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareProtocolAssignments(_ store: any GlobalCareProtocolAssignmentStore, query: GlobalCareProtocolAssignmentQuery) -> [GlobalCareProtocolAssignment] {
        return query.apply(store.list())
    }
}
