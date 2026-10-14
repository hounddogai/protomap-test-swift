import AcmePlatform
import Foundation

extension Consent {
    /// Keeps strict disclosure segments by code.
    protocol StrictDisclosureSegmentStore {
        func find(_ code: String) -> StrictDisclosureSegment?
        func save(_ item: StrictDisclosureSegment)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDisclosureSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDisclosureSegmentStore: StrictDisclosureSegmentStore {
        var items: [String: StrictDisclosureSegment]
        var order: [String]

        init(items: [String: StrictDisclosureSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDisclosureSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDisclosureSegment) {
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

        func list() -> [StrictDisclosureSegment] {
            var out: [StrictDisclosureSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDisclosureSegmentStore() -> any StrictDisclosureSegmentStore {
        return MemoryStrictDisclosureSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDisclosureSegmentStore: StrictDisclosureSegmentStore {
        var inner: MemoryStrictDisclosureSegmentStore
        var cache: TTLCache<StrictDisclosureSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDisclosureSegmentStore, cache: TTLCache<StrictDisclosureSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDisclosureSegment? {
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

        func save(_ item: StrictDisclosureSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDisclosureSegment] {
            return inner.list()
        }
    }

    static func newCachedStrictDisclosureSegmentStore(_ inner: MemoryStrictDisclosureSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDisclosureSegmentStore {
        return CachedStrictDisclosureSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict disclosure segments. Empty fields match all.
    final class StrictDisclosureSegmentQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDisclosureSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictDisclosureSegment]) -> [StrictDisclosureSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDisclosureSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDisclosureSegments(_ store: any StrictDisclosureSegmentStore, query: StrictDisclosureSegmentQuery) -> [StrictDisclosureSegment] {
        return query.apply(store.list())
    }
}
