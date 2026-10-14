import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling charge records by code.
    protocol RollingChargeRecordStore {
        func find(_ code: String) -> RollingChargeRecord?
        func save(_ item: RollingChargeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RollingChargeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingChargeRecordStore: RollingChargeRecordStore {
        var items: [String: RollingChargeRecord]
        var order: [String]

        init(items: [String: RollingChargeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingChargeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingChargeRecord) {
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

        func list() -> [RollingChargeRecord] {
            var out: [RollingChargeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingChargeRecordStore() -> any RollingChargeRecordStore {
        return MemoryRollingChargeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingChargeRecordStore: RollingChargeRecordStore {
        var inner: MemoryRollingChargeRecordStore
        var cache: TTLCache<RollingChargeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingChargeRecordStore, cache: TTLCache<RollingChargeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingChargeRecord? {
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

        func save(_ item: RollingChargeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingChargeRecord] {
            return inner.list()
        }
    }

    static func newCachedRollingChargeRecordStore(_ inner: MemoryRollingChargeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingChargeRecordStore {
        return CachedRollingChargeRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling charge records. Empty fields match all.
    final class RollingChargeRecordQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingChargeRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RollingChargeRecord]) -> [RollingChargeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingChargeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingChargeRecords(_ store: any RollingChargeRecordStore, query: RollingChargeRecordQuery) -> [RollingChargeRecord] {
        return query.apply(store.list())
    }
}
