import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global network records by code.
    protocol GlobalNetworkRecordStore {
        func find(_ code: String) -> GlobalNetworkRecord?
        func save(_ item: GlobalNetworkRecord)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalNetworkRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalNetworkRecordStore: GlobalNetworkRecordStore {
        var items: [String: GlobalNetworkRecord]
        var order: [String]

        init(items: [String: GlobalNetworkRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalNetworkRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalNetworkRecord) {
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

        func list() -> [GlobalNetworkRecord] {
            var out: [GlobalNetworkRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalNetworkRecordStore() -> any GlobalNetworkRecordStore {
        return MemoryGlobalNetworkRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalNetworkRecordStore: GlobalNetworkRecordStore {
        var inner: MemoryGlobalNetworkRecordStore
        var cache: TTLCache<GlobalNetworkRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalNetworkRecordStore, cache: TTLCache<GlobalNetworkRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalNetworkRecord? {
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

        func save(_ item: GlobalNetworkRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalNetworkRecord] {
            return inner.list()
        }
    }

    static func newCachedGlobalNetworkRecordStore(_ inner: MemoryGlobalNetworkRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalNetworkRecordStore {
        return CachedGlobalNetworkRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global network records. Empty fields match all.
    final class GlobalNetworkRecordQuery {
        var source: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalNetworkRecord) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [GlobalNetworkRecord]) -> [GlobalNetworkRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalNetworkRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalNetworkRecords(_ store: any GlobalNetworkRecordStore, query: GlobalNetworkRecordQuery) -> [GlobalNetworkRecord] {
        return query.apply(store.list())
    }
}
