import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped network drafts by code.
    protocol CappedNetworkDraftStore {
        func find(_ code: String) -> CappedNetworkDraft?
        func save(_ item: CappedNetworkDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CappedNetworkDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedNetworkDraftStore: CappedNetworkDraftStore {
        var items: [String: CappedNetworkDraft]
        var order: [String]

        init(items: [String: CappedNetworkDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedNetworkDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedNetworkDraft) {
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

        func list() -> [CappedNetworkDraft] {
            var out: [CappedNetworkDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedNetworkDraftStore() -> any CappedNetworkDraftStore {
        return MemoryCappedNetworkDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedNetworkDraftStore: CappedNetworkDraftStore {
        var inner: MemoryCappedNetworkDraftStore
        var cache: TTLCache<CappedNetworkDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedNetworkDraftStore, cache: TTLCache<CappedNetworkDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedNetworkDraft? {
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

        func save(_ item: CappedNetworkDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedNetworkDraft] {
            return inner.list()
        }
    }

    static func newCachedCappedNetworkDraftStore(_ inner: MemoryCappedNetworkDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedNetworkDraftStore {
        return CachedCappedNetworkDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped network drafts. Empty fields match all.
    final class CappedNetworkDraftQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedNetworkDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [CappedNetworkDraft]) -> [CappedNetworkDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedNetworkDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedNetworkDrafts(_ store: any CappedNetworkDraftStore, query: CappedNetworkDraftQuery) -> [CappedNetworkDraft] {
        return query.apply(store.list())
    }
}
