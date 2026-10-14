import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge records by code.
    protocol ChargeRecordStore {
        func find(_ code: String) -> ChargeRecord?
        func save(_ item: ChargeRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeRecordStore: ChargeRecordStore {
        var items: [String: ChargeRecord]
        var order: [String]

        init(items: [String: ChargeRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeRecord) {
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

        func list() -> [ChargeRecord] {
            var out: [ChargeRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeRecordStore() -> any ChargeRecordStore {
        return MemoryChargeRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeRecordStore: ChargeRecordStore {
        var inner: MemoryChargeRecordStore
        var cache: TTLCache<ChargeRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeRecordStore, cache: TTLCache<ChargeRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeRecord? {
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

        func save(_ item: ChargeRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeRecord] {
            return inner.list()
        }
    }

    static func newCachedChargeRecordStore(_ inner: MemoryChargeRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeRecordStore {
        return CachedChargeRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge records. Empty fields match all.
    final class ChargeRecordQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeRecord]) -> [ChargeRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeRecords(_ store: any ChargeRecordStore, query: ChargeRecordQuery) -> [ChargeRecord] {
        return query.apply(store.list())
    }
}
