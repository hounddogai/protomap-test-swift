import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted recall drafts by code.
    protocol WeightedRecallDraftStore {
        func find(_ code: String) -> WeightedRecallDraft?
        func save(_ item: WeightedRecallDraft)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedRecallDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedRecallDraftStore: WeightedRecallDraftStore {
        var items: [String: WeightedRecallDraft]
        var order: [String]

        init(items: [String: WeightedRecallDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedRecallDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedRecallDraft) {
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

        func list() -> [WeightedRecallDraft] {
            var out: [WeightedRecallDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedRecallDraftStore() -> any WeightedRecallDraftStore {
        return MemoryWeightedRecallDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedRecallDraftStore: WeightedRecallDraftStore {
        var inner: MemoryWeightedRecallDraftStore
        var cache: TTLCache<WeightedRecallDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedRecallDraftStore, cache: TTLCache<WeightedRecallDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedRecallDraft? {
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

        func save(_ item: WeightedRecallDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedRecallDraft] {
            return inner.list()
        }
    }

    static func newCachedWeightedRecallDraftStore(_ inner: MemoryWeightedRecallDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedRecallDraftStore {
        return CachedWeightedRecallDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted recall drafts. Empty fields match all.
    final class WeightedRecallDraftQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedRecallDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [WeightedRecallDraft]) -> [WeightedRecallDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedRecallDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedRecallDrafts(_ store: any WeightedRecallDraftStore, query: WeightedRecallDraftQuery) -> [WeightedRecallDraft] {
        return query.apply(store.list())
    }
}
