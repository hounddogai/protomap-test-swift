import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense quotas by code.
    protocol DispenseQuotaStore {
        func find(_ code: String) -> DispenseQuota?
        func save(_ item: DispenseQuota)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseQuotaStore: DispenseQuotaStore {
        var items: [String: DispenseQuota]
        var order: [String]

        init(items: [String: DispenseQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseQuota) {
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

        func list() -> [DispenseQuota] {
            var out: [DispenseQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseQuotaStore() -> any DispenseQuotaStore {
        return MemoryDispenseQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseQuotaStore: DispenseQuotaStore {
        var inner: MemoryDispenseQuotaStore
        var cache: TTLCache<DispenseQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseQuotaStore, cache: TTLCache<DispenseQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseQuota? {
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

        func save(_ item: DispenseQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseQuota] {
            return inner.list()
        }
    }

    static func newCachedDispenseQuotaStore(_ inner: MemoryDispenseQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseQuotaStore {
        return CachedDispenseQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense quotas. Empty fields match all.
    final class DispenseQuotaQuery {
        var channel: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseQuota) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseQuota]) -> [DispenseQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseQuotas(_ store: any DispenseQuotaStore, query: DispenseQuotaQuery) -> [DispenseQuota] {
        return query.apply(store.list())
    }
}
