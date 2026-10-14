import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board quotas by code.
    protocol BedBoardQuotaStore {
        func find(_ code: String) -> BedBoardQuota?
        func save(_ item: BedBoardQuota)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardQuotaStore: BedBoardQuotaStore {
        var items: [String: BedBoardQuota]
        var order: [String]

        init(items: [String: BedBoardQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardQuota) {
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

        func list() -> [BedBoardQuota] {
            var out: [BedBoardQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardQuotaStore() -> any BedBoardQuotaStore {
        return MemoryBedBoardQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardQuotaStore: BedBoardQuotaStore {
        var inner: MemoryBedBoardQuotaStore
        var cache: TTLCache<BedBoardQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardQuotaStore, cache: TTLCache<BedBoardQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardQuota? {
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

        func save(_ item: BedBoardQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardQuota] {
            return inner.list()
        }
    }

    static func newCachedBedBoardQuotaStore(_ inner: MemoryBedBoardQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardQuotaStore {
        return CachedBedBoardQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board quotas. Empty fields match all.
    final class BedBoardQuotaQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardQuota]) -> [BedBoardQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardQuotas(_ store: any BedBoardQuotaStore, query: BedBoardQuotaQuery) -> [BedBoardQuota] {
        return query.apply(store.list())
    }
}
