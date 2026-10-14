import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority claims by code.
    protocol PriorityClaimStore {
        func find(_ code: String) -> PriorityClaim?
        func save(_ item: PriorityClaim)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityClaimStore: PriorityClaimStore {
        var items: [String: PriorityClaim]
        var order: [String]

        init(items: [String: PriorityClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityClaim) {
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

        func list() -> [PriorityClaim] {
            var out: [PriorityClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityClaimStore() -> any PriorityClaimStore {
        return MemoryPriorityClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityClaimStore: PriorityClaimStore {
        var inner: MemoryPriorityClaimStore
        var cache: TTLCache<PriorityClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityClaimStore, cache: TTLCache<PriorityClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityClaim? {
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

        func save(_ item: PriorityClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityClaim] {
            return inner.list()
        }
    }

    static func newCachedPriorityClaimStore(_ inner: MemoryPriorityClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityClaimStore {
        return CachedPriorityClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority claims. Empty fields match all.
    final class PriorityClaimQuery {
        var category: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minSequence: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityClaim) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityClaim]) -> [PriorityClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityClaims(_ store: any PriorityClaimStore, query: PriorityClaimQuery) -> [PriorityClaim] {
        return query.apply(store.list())
    }
}
