import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending alert tiers by code.
    protocol PendingAlertTierStore {
        func find(_ code: String) -> PendingAlertTier?
        func save(_ item: PendingAlertTier)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAlertTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAlertTierStore: PendingAlertTierStore {
        var items: [String: PendingAlertTier]
        var order: [String]

        init(items: [String: PendingAlertTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAlertTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAlertTier) {
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

        func list() -> [PendingAlertTier] {
            var out: [PendingAlertTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAlertTierStore() -> any PendingAlertTierStore {
        return MemoryPendingAlertTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAlertTierStore: PendingAlertTierStore {
        var inner: MemoryPendingAlertTierStore
        var cache: TTLCache<PendingAlertTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAlertTierStore, cache: TTLCache<PendingAlertTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAlertTier? {
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

        func save(_ item: PendingAlertTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAlertTier] {
            return inner.list()
        }
    }

    static func newCachedPendingAlertTierStore(_ inner: MemoryPendingAlertTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAlertTierStore {
        return CachedPendingAlertTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending alert tiers. Empty fields match all.
    final class PendingAlertTierQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAlertTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingAlertTier]) -> [PendingAlertTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAlertTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAlertTiers(_ store: any PendingAlertTierStore, query: PendingAlertTierQuery) -> [PendingAlertTier] {
        return query.apply(store.list())
    }
}
