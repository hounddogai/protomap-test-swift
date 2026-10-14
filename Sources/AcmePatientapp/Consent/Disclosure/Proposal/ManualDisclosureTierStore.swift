import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual disclosure tiers by code.
    protocol ManualDisclosureTierStore {
        func find(_ code: String) -> ManualDisclosureTier?
        func save(_ item: ManualDisclosureTier)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDisclosureTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDisclosureTierStore: ManualDisclosureTierStore {
        var items: [String: ManualDisclosureTier]
        var order: [String]

        init(items: [String: ManualDisclosureTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDisclosureTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDisclosureTier) {
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

        func list() -> [ManualDisclosureTier] {
            var out: [ManualDisclosureTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDisclosureTierStore() -> any ManualDisclosureTierStore {
        return MemoryManualDisclosureTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDisclosureTierStore: ManualDisclosureTierStore {
        var inner: MemoryManualDisclosureTierStore
        var cache: TTLCache<ManualDisclosureTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDisclosureTierStore, cache: TTLCache<ManualDisclosureTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDisclosureTier? {
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

        func save(_ item: ManualDisclosureTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDisclosureTier] {
            return inner.list()
        }
    }

    static func newCachedManualDisclosureTierStore(_ inner: MemoryManualDisclosureTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDisclosureTierStore {
        return CachedManualDisclosureTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual disclosure tiers. Empty fields match all.
    final class ManualDisclosureTierQuery {
        var facility: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRevision: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDisclosureTier) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDisclosureTier]) -> [ManualDisclosureTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDisclosureTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDisclosureTiers(_ store: any ManualDisclosureTierStore, query: ManualDisclosureTierQuery) -> [ManualDisclosureTier] {
        return query.apply(store.list())
    }
}
