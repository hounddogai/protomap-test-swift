import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance records by code.
    protocol RemittanceRecordStore {
        func find(_ code: String) -> RemittanceRecord?
        func save(_ item: RemittanceRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceRecordStore: RemittanceRecordStore {
        var items: [String: RemittanceRecord]
        var order: [String]

        init(items: [String: RemittanceRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceRecord) {
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

        func list() -> [RemittanceRecord] {
            var out: [RemittanceRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceRecordStore() -> any RemittanceRecordStore {
        return MemoryRemittanceRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceRecordStore: RemittanceRecordStore {
        var inner: MemoryRemittanceRecordStore
        var cache: TTLCache<RemittanceRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceRecordStore, cache: TTLCache<RemittanceRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceRecord? {
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

        func save(_ item: RemittanceRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceRecord] {
            return inner.list()
        }
    }

    static func newCachedRemittanceRecordStore(_ inner: MemoryRemittanceRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceRecordStore {
        return CachedRemittanceRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance records. Empty fields match all.
    final class RemittanceRecordQuery {
        var country: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minBudget: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceRecord) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceRecord]) -> [RemittanceRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceRecords(_ store: any RemittanceRecordStore, query: RemittanceRecordQuery) -> [RemittanceRecord] {
        return query.apply(store.list())
    }
}
