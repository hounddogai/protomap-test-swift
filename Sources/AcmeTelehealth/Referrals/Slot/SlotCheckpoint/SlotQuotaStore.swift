import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot quotas by code.
    protocol SlotQuotaStore {
        func find(_ code: String) -> SlotQuota?
        func save(_ item: SlotQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SlotQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotQuotaStore: SlotQuotaStore {
        var items: [String: SlotQuota]
        var order: [String]

        init(items: [String: SlotQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotQuota) {
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

        func list() -> [SlotQuota] {
            var out: [SlotQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotQuotaStore() -> any SlotQuotaStore {
        return MemorySlotQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotQuotaStore: SlotQuotaStore {
        var inner: MemorySlotQuotaStore
        var cache: TTLCache<SlotQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotQuotaStore, cache: TTLCache<SlotQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotQuota? {
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

        func save(_ item: SlotQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotQuota] {
            return inner.list()
        }
    }

    static func newCachedSlotQuotaStore(_ inner: MemorySlotQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotQuotaStore {
        return CachedSlotQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot quotas. Empty fields match all.
    final class SlotQuotaQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotQuota]) -> [SlotQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotQuotas(_ store: any SlotQuotaStore, query: SlotQuotaQuery) -> [SlotQuota] {
        return query.apply(store.list())
    }
}
