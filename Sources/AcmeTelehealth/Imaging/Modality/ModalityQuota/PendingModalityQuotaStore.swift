import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending modality quotas by code.
    protocol PendingModalityQuotaStore {
        func find(_ code: String) -> PendingModalityQuota?
        func save(_ item: PendingModalityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PendingModalityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingModalityQuotaStore: PendingModalityQuotaStore {
        var items: [String: PendingModalityQuota]
        var order: [String]

        init(items: [String: PendingModalityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingModalityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingModalityQuota) {
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

        func list() -> [PendingModalityQuota] {
            var out: [PendingModalityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingModalityQuotaStore() -> any PendingModalityQuotaStore {
        return MemoryPendingModalityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingModalityQuotaStore: PendingModalityQuotaStore {
        var inner: MemoryPendingModalityQuotaStore
        var cache: TTLCache<PendingModalityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingModalityQuotaStore, cache: TTLCache<PendingModalityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingModalityQuota? {
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

        func save(_ item: PendingModalityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingModalityQuota] {
            return inner.list()
        }
    }

    static func newCachedPendingModalityQuotaStore(_ inner: MemoryPendingModalityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingModalityQuotaStore {
        return CachedPendingModalityQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending modality quotas. Empty fields match all.
    final class PendingModalityQuotaQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingModalityQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingModalityQuota]) -> [PendingModalityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingModalityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingModalityQuotas(_ store: any PendingModalityQuotaStore, query: PendingModalityQuotaQuery) -> [PendingModalityQuota] {
        return query.apply(store.list())
    }
}
