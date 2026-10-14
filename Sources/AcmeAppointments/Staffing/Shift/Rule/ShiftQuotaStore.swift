import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift quotas by code.
    protocol ShiftQuotaStore {
        func find(_ code: String) -> ShiftQuota?
        func save(_ item: ShiftQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftQuotaStore: ShiftQuotaStore {
        var items: [String: ShiftQuota]
        var order: [String]

        init(items: [String: ShiftQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftQuota) {
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

        func list() -> [ShiftQuota] {
            var out: [ShiftQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftQuotaStore() -> any ShiftQuotaStore {
        return MemoryShiftQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftQuotaStore: ShiftQuotaStore {
        var inner: MemoryShiftQuotaStore
        var cache: TTLCache<ShiftQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftQuotaStore, cache: TTLCache<ShiftQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftQuota? {
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

        func save(_ item: ShiftQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftQuota] {
            return inner.list()
        }
    }

    static func newCachedShiftQuotaStore(_ inner: MemoryShiftQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftQuotaStore {
        return CachedShiftQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift quotas. Empty fields match all.
    final class ShiftQuotaQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ShiftQuota]) -> [ShiftQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftQuotas(_ store: any ShiftQuotaStore, query: ShiftQuotaQuery) -> [ShiftQuota] {
        return query.apply(store.list())
    }
}
