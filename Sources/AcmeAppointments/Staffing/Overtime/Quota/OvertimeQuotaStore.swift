import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime quotas by code.
    protocol OvertimeQuotaStore {
        func find(_ code: String) -> OvertimeQuota?
        func save(_ item: OvertimeQuota)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeQuotaStore: OvertimeQuotaStore {
        var items: [String: OvertimeQuota]
        var order: [String]

        init(items: [String: OvertimeQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeQuota) {
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

        func list() -> [OvertimeQuota] {
            var out: [OvertimeQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeQuotaStore() -> any OvertimeQuotaStore {
        return MemoryOvertimeQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeQuotaStore: OvertimeQuotaStore {
        var inner: MemoryOvertimeQuotaStore
        var cache: TTLCache<OvertimeQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeQuotaStore, cache: TTLCache<OvertimeQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeQuota? {
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

        func save(_ item: OvertimeQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeQuota] {
            return inner.list()
        }
    }

    static func newCachedOvertimeQuotaStore(_ inner: MemoryOvertimeQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeQuotaStore {
        return CachedOvertimeQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime quotas. Empty fields match all.
    final class OvertimeQuotaQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeQuota]) -> [OvertimeQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeQuotas(_ store: any OvertimeQuotaStore, query: OvertimeQuotaQuery) -> [OvertimeQuota] {
        return query.apply(store.list())
    }
}
