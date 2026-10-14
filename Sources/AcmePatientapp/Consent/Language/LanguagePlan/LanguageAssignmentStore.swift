import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language assignments by code.
    protocol LanguageAssignmentStore {
        func find(_ code: String) -> LanguageAssignment?
        func save(_ item: LanguageAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageAssignmentStore: LanguageAssignmentStore {
        var items: [String: LanguageAssignment]
        var order: [String]

        init(items: [String: LanguageAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageAssignment) {
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

        func list() -> [LanguageAssignment] {
            var out: [LanguageAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageAssignmentStore() -> any LanguageAssignmentStore {
        return MemoryLanguageAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageAssignmentStore: LanguageAssignmentStore {
        var inner: MemoryLanguageAssignmentStore
        var cache: TTLCache<LanguageAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageAssignmentStore, cache: TTLCache<LanguageAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageAssignment? {
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

        func save(_ item: LanguageAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageAssignment] {
            return inner.list()
        }
    }

    static func newCachedLanguageAssignmentStore(_ inner: MemoryLanguageAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageAssignmentStore {
        return CachedLanguageAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language assignments. Empty fields match all.
    final class LanguageAssignmentQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LanguageAssignment]) -> [LanguageAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageAssignments(_ store: any LanguageAssignmentStore, query: LanguageAssignmentQuery) -> [LanguageAssignment] {
        return query.apply(store.list())
    }
}
