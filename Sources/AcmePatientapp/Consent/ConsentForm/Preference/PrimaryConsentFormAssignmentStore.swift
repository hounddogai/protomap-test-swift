import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary consent form assignments by code.
    protocol PrimaryConsentFormAssignmentStore {
        func find(_ code: String) -> PrimaryConsentFormAssignment?
        func save(_ item: PrimaryConsentFormAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryConsentFormAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryConsentFormAssignmentStore: PrimaryConsentFormAssignmentStore {
        var items: [String: PrimaryConsentFormAssignment]
        var order: [String]

        init(items: [String: PrimaryConsentFormAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryConsentFormAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryConsentFormAssignment) {
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

        func list() -> [PrimaryConsentFormAssignment] {
            var out: [PrimaryConsentFormAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryConsentFormAssignmentStore() -> any PrimaryConsentFormAssignmentStore {
        return MemoryPrimaryConsentFormAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryConsentFormAssignmentStore: PrimaryConsentFormAssignmentStore {
        var inner: MemoryPrimaryConsentFormAssignmentStore
        var cache: TTLCache<PrimaryConsentFormAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryConsentFormAssignmentStore, cache: TTLCache<PrimaryConsentFormAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryConsentFormAssignment? {
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

        func save(_ item: PrimaryConsentFormAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryConsentFormAssignment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryConsentFormAssignmentStore(_ inner: MemoryPrimaryConsentFormAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryConsentFormAssignmentStore {
        return CachedPrimaryConsentFormAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary consent form assignments. Empty fields match all.
    final class PrimaryConsentFormAssignmentQuery {
        var country: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCost: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryConsentFormAssignment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryConsentFormAssignment]) -> [PrimaryConsentFormAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryConsentFormAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryConsentFormAssignments(_ store: any PrimaryConsentFormAssignmentStore, query: PrimaryConsentFormAssignmentQuery) -> [PrimaryConsentFormAssignment] {
        return query.apply(store.list())
    }
}
