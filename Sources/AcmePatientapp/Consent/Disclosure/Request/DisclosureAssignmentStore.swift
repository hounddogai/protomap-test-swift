import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure assignments by code.
    protocol DisclosureAssignmentStore {
        func find(_ code: String) -> DisclosureAssignment?
        func save(_ item: DisclosureAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureAssignmentStore: DisclosureAssignmentStore {
        var items: [String: DisclosureAssignment]
        var order: [String]

        init(items: [String: DisclosureAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureAssignment) {
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

        func list() -> [DisclosureAssignment] {
            var out: [DisclosureAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureAssignmentStore() -> any DisclosureAssignmentStore {
        return MemoryDisclosureAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureAssignmentStore: DisclosureAssignmentStore {
        var inner: MemoryDisclosureAssignmentStore
        var cache: TTLCache<DisclosureAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureAssignmentStore, cache: TTLCache<DisclosureAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureAssignment? {
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

        func save(_ item: DisclosureAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureAssignment] {
            return inner.list()
        }
    }

    static func newCachedDisclosureAssignmentStore(_ inner: MemoryDisclosureAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureAssignmentStore {
        return CachedDisclosureAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure assignments. Empty fields match all.
    final class DisclosureAssignmentQuery {
        var locale: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureAssignment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureAssignment]) -> [DisclosureAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureAssignments(_ store: any DisclosureAssignmentStore, query: DisclosureAssignmentQuery) -> [DisclosureAssignment] {
        return query.apply(store.list())
    }
}
