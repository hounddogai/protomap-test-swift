import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive network drafts by code.
    protocol AdaptiveNetworkDraftStore {
        func find(_ code: String) -> AdaptiveNetworkDraft?
        func save(_ item: AdaptiveNetworkDraft)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveNetworkDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveNetworkDraftStore: AdaptiveNetworkDraftStore {
        var items: [String: AdaptiveNetworkDraft]
        var order: [String]

        init(items: [String: AdaptiveNetworkDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveNetworkDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveNetworkDraft) {
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

        func list() -> [AdaptiveNetworkDraft] {
            var out: [AdaptiveNetworkDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveNetworkDraftStore() -> any AdaptiveNetworkDraftStore {
        return MemoryAdaptiveNetworkDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveNetworkDraftStore: AdaptiveNetworkDraftStore {
        var inner: MemoryAdaptiveNetworkDraftStore
        var cache: TTLCache<AdaptiveNetworkDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveNetworkDraftStore, cache: TTLCache<AdaptiveNetworkDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveNetworkDraft? {
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

        func save(_ item: AdaptiveNetworkDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveNetworkDraft] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveNetworkDraftStore(_ inner: MemoryAdaptiveNetworkDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveNetworkDraftStore {
        return CachedAdaptiveNetworkDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive network drafts. Empty fields match all.
    final class AdaptiveNetworkDraftQuery {
        var category: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveNetworkDraft) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [AdaptiveNetworkDraft]) -> [AdaptiveNetworkDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveNetworkDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveNetworkDrafts(_ store: any AdaptiveNetworkDraftStore, query: AdaptiveNetworkDraftQuery) -> [AdaptiveNetworkDraft] {
        return query.apply(store.list())
    }
}
