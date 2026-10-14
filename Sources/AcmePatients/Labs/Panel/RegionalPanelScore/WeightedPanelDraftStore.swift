import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted panel drafts by code.
    protocol WeightedPanelDraftStore {
        func find(_ code: String) -> WeightedPanelDraft?
        func save(_ item: WeightedPanelDraft)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedPanelDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedPanelDraftStore: WeightedPanelDraftStore {
        var items: [String: WeightedPanelDraft]
        var order: [String]

        init(items: [String: WeightedPanelDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedPanelDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedPanelDraft) {
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

        func list() -> [WeightedPanelDraft] {
            var out: [WeightedPanelDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedPanelDraftStore() -> any WeightedPanelDraftStore {
        return MemoryWeightedPanelDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedPanelDraftStore: WeightedPanelDraftStore {
        var inner: MemoryWeightedPanelDraftStore
        var cache: TTLCache<WeightedPanelDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedPanelDraftStore, cache: TTLCache<WeightedPanelDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedPanelDraft? {
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

        func save(_ item: WeightedPanelDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedPanelDraft] {
            return inner.list()
        }
    }

    static func newCachedWeightedPanelDraftStore(_ inner: MemoryWeightedPanelDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedPanelDraftStore {
        return CachedWeightedPanelDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted panel drafts. Empty fields match all.
    final class WeightedPanelDraftQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedPanelDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedPanelDraft]) -> [WeightedPanelDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedPanelDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedPanelDrafts(_ store: any WeightedPanelDraftStore, query: WeightedPanelDraftQuery) -> [WeightedPanelDraft] {
        return query.apply(store.list())
    }
}
