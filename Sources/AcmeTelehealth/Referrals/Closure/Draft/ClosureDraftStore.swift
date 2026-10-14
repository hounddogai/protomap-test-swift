import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure drafts by code.
    protocol ClosureDraftStore {
        func find(_ code: String) -> ClosureDraft?
        func save(_ item: ClosureDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureDraftStore: ClosureDraftStore {
        var items: [String: ClosureDraft]
        var order: [String]

        init(items: [String: ClosureDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureDraft) {
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

        func list() -> [ClosureDraft] {
            var out: [ClosureDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureDraftStore() -> any ClosureDraftStore {
        return MemoryClosureDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureDraftStore: ClosureDraftStore {
        var inner: MemoryClosureDraftStore
        var cache: TTLCache<ClosureDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureDraftStore, cache: TTLCache<ClosureDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureDraft? {
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

        func save(_ item: ClosureDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureDraft] {
            return inner.list()
        }
    }

    static func newCachedClosureDraftStore(_ inner: MemoryClosureDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureDraftStore {
        return CachedClosureDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure drafts. Empty fields match all.
    final class ClosureDraftQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureDraft) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureDraft]) -> [ClosureDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureDrafts(_ store: any ClosureDraftStore, query: ClosureDraftQuery) -> [ClosureDraft] {
        return query.apply(store.list())
    }
}
