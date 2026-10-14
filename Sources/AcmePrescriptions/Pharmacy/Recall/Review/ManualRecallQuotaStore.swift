import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual recall quotas by code.
    protocol ManualRecallQuotaStore {
        func find(_ code: String) -> ManualRecallQuota?
        func save(_ item: ManualRecallQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRecallQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRecallQuotaStore: ManualRecallQuotaStore {
        var items: [String: ManualRecallQuota]
        var order: [String]

        init(items: [String: ManualRecallQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRecallQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRecallQuota) {
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

        func list() -> [ManualRecallQuota] {
            var out: [ManualRecallQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRecallQuotaStore() -> any ManualRecallQuotaStore {
        return MemoryManualRecallQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRecallQuotaStore: ManualRecallQuotaStore {
        var inner: MemoryManualRecallQuotaStore
        var cache: TTLCache<ManualRecallQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRecallQuotaStore, cache: TTLCache<ManualRecallQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRecallQuota? {
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

        func save(_ item: ManualRecallQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRecallQuota] {
            return inner.list()
        }
    }

    static func newCachedManualRecallQuotaStore(_ inner: MemoryManualRecallQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRecallQuotaStore {
        return CachedManualRecallQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual recall quotas. Empty fields match all.
    final class ManualRecallQuotaQuery {
        var source: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRecallQuota) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRecallQuota]) -> [ManualRecallQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRecallQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRecallQuotas(_ store: any ManualRecallQuotaStore, query: ManualRecallQuotaQuery) -> [ManualRecallQuota] {
        return query.apply(store.list())
    }
}
