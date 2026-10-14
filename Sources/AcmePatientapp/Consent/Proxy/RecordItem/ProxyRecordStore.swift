import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy records by code.
    protocol ProxyRecordStore {
        func find(_ code: String) -> ProxyRecord?
        func save(_ item: ProxyRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyRecordStore: ProxyRecordStore {
        var items: [String: ProxyRecord]
        var order: [String]

        init(items: [String: ProxyRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyRecord) {
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

        func list() -> [ProxyRecord] {
            var out: [ProxyRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyRecordStore() -> any ProxyRecordStore {
        return MemoryProxyRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyRecordStore: ProxyRecordStore {
        var inner: MemoryProxyRecordStore
        var cache: TTLCache<ProxyRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyRecordStore, cache: TTLCache<ProxyRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyRecord? {
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

        func save(_ item: ProxyRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyRecord] {
            return inner.list()
        }
    }

    static func newCachedProxyRecordStore(_ inner: MemoryProxyRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyRecordStore {
        return CachedProxyRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy records. Empty fields match all.
    final class ProxyRecordQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ProxyRecord]) -> [ProxyRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyRecords(_ store: any ProxyRecordStore, query: ProxyRecordQuery) -> [ProxyRecord] {
        return query.apply(store.list())
    }
}
