import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual witness drafts by code.
    protocol ManualWitnessDraftStore {
        func find(_ code: String) -> ManualWitnessDraft?
        func save(_ item: ManualWitnessDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ManualWitnessDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualWitnessDraftStore: ManualWitnessDraftStore {
        var items: [String: ManualWitnessDraft]
        var order: [String]

        init(items: [String: ManualWitnessDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualWitnessDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualWitnessDraft) {
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

        func list() -> [ManualWitnessDraft] {
            var out: [ManualWitnessDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualWitnessDraftStore() -> any ManualWitnessDraftStore {
        return MemoryManualWitnessDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualWitnessDraftStore: ManualWitnessDraftStore {
        var inner: MemoryManualWitnessDraftStore
        var cache: TTLCache<ManualWitnessDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualWitnessDraftStore, cache: TTLCache<ManualWitnessDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualWitnessDraft? {
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

        func save(_ item: ManualWitnessDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualWitnessDraft] {
            return inner.list()
        }
    }

    static func newCachedManualWitnessDraftStore(_ inner: MemoryManualWitnessDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualWitnessDraftStore {
        return CachedManualWitnessDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual witness drafts. Empty fields match all.
    final class ManualWitnessDraftQuery {
        var segment: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCost: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualWitnessDraft) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualWitnessDraft]) -> [ManualWitnessDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualWitnessDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualWitnessDrafts(_ store: any ManualWitnessDraftStore, query: ManualWitnessDraftQuery) -> [ManualWitnessDraft] {
        return query.apply(store.list())
    }
}
