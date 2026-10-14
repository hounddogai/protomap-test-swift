import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network records by code.
    protocol NetworkRecordStore {
        func find(_ code: String) -> NetworkRecord?
        func save(_ item: NetworkRecord)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkRecordStore: NetworkRecordStore {
        var items: [String: NetworkRecord]
        var order: [String]

        init(items: [String: NetworkRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkRecord) {
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

        func list() -> [NetworkRecord] {
            var out: [NetworkRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkRecordStore() -> any NetworkRecordStore {
        return MemoryNetworkRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkRecordStore: NetworkRecordStore {
        var inner: MemoryNetworkRecordStore
        var cache: TTLCache<NetworkRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkRecordStore, cache: TTLCache<NetworkRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkRecord? {
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

        func save(_ item: NetworkRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkRecord] {
            return inner.list()
        }
    }

    static func newCachedNetworkRecordStore(_ inner: MemoryNetworkRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkRecordStore {
        return CachedNetworkRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network records. Empty fields match all.
    final class NetworkRecordQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkRecord) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkRecord]) -> [NetworkRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkRecords(_ store: any NetworkRecordStore, query: NetworkRecordQuery) -> [NetworkRecord] {
        return query.apply(store.list())
    }
}
