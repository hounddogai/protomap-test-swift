import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert records by code.
    protocol AlertRecordStore {
        func find(_ code: String) -> AlertRecord?
        func save(_ item: AlertRecord)
        func remove(_ code: String) -> Bool
        func list() -> [AlertRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertRecordStore: AlertRecordStore {
        var items: [String: AlertRecord]
        var order: [String]

        init(items: [String: AlertRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertRecord) {
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

        func list() -> [AlertRecord] {
            var out: [AlertRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertRecordStore() -> any AlertRecordStore {
        return MemoryAlertRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertRecordStore: AlertRecordStore {
        var inner: MemoryAlertRecordStore
        var cache: TTLCache<AlertRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertRecordStore, cache: TTLCache<AlertRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertRecord? {
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

        func save(_ item: AlertRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertRecord] {
            return inner.list()
        }
    }

    static func newCachedAlertRecordStore(_ inner: MemoryAlertRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertRecordStore {
        return CachedAlertRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert records. Empty fields match all.
    final class AlertRecordQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertRecord]) -> [AlertRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertRecords(_ store: any AlertRecordStore, query: AlertRecordQuery) -> [AlertRecord] {
        return query.apply(store.list())
    }
}
