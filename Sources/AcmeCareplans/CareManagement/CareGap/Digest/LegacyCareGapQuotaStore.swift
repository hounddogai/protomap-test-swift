import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy care gap quotas by code.
    protocol LegacyCareGapQuotaStore {
        func find(_ code: String) -> LegacyCareGapQuota?
        func save(_ item: LegacyCareGapQuota)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCareGapQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCareGapQuotaStore: LegacyCareGapQuotaStore {
        var items: [String: LegacyCareGapQuota]
        var order: [String]

        init(items: [String: LegacyCareGapQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCareGapQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCareGapQuota) {
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

        func list() -> [LegacyCareGapQuota] {
            var out: [LegacyCareGapQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCareGapQuotaStore() -> any LegacyCareGapQuotaStore {
        return MemoryLegacyCareGapQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCareGapQuotaStore: LegacyCareGapQuotaStore {
        var inner: MemoryLegacyCareGapQuotaStore
        var cache: TTLCache<LegacyCareGapQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCareGapQuotaStore, cache: TTLCache<LegacyCareGapQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCareGapQuota? {
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

        func save(_ item: LegacyCareGapQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCareGapQuota] {
            return inner.list()
        }
    }

    static func newCachedLegacyCareGapQuotaStore(_ inner: MemoryLegacyCareGapQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCareGapQuotaStore {
        return CachedLegacyCareGapQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy care gap quotas. Empty fields match all.
    final class LegacyCareGapQuotaQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCareGapQuota) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCareGapQuota]) -> [LegacyCareGapQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCareGapQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCareGapQuotas(_ store: any LegacyCareGapQuotaStore, query: LegacyCareGapQuotaQuery) -> [LegacyCareGapQuota] {
        return query.apply(store.list())
    }
}
