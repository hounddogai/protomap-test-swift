import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback modality quotas by code.
    protocol FallbackModalityQuotaStore {
        func find(_ code: String) -> FallbackModalityQuota?
        func save(_ item: FallbackModalityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackModalityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackModalityQuotaStore: FallbackModalityQuotaStore {
        var items: [String: FallbackModalityQuota]
        var order: [String]

        init(items: [String: FallbackModalityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackModalityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackModalityQuota) {
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

        func list() -> [FallbackModalityQuota] {
            var out: [FallbackModalityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackModalityQuotaStore() -> any FallbackModalityQuotaStore {
        return MemoryFallbackModalityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackModalityQuotaStore: FallbackModalityQuotaStore {
        var inner: MemoryFallbackModalityQuotaStore
        var cache: TTLCache<FallbackModalityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackModalityQuotaStore, cache: TTLCache<FallbackModalityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackModalityQuota? {
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

        func save(_ item: FallbackModalityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackModalityQuota] {
            return inner.list()
        }
    }

    static func newCachedFallbackModalityQuotaStore(_ inner: MemoryFallbackModalityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackModalityQuotaStore {
        return CachedFallbackModalityQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback modality quotas. Empty fields match all.
    final class FallbackModalityQuotaQuery {
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

        func matches(_ item: FallbackModalityQuota) -> Bool {
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

        func apply(_ items: [FallbackModalityQuota]) -> [FallbackModalityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackModalityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackModalityQuotas(_ store: any FallbackModalityQuotaStore, query: FallbackModalityQuotaQuery) -> [FallbackModalityQuota] {
        return query.apply(store.list())
    }
}
