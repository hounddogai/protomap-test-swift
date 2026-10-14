import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan records by code.
    protocol AcuityPlanRecordStore {
        func find(_ code: String) -> AcuityPlanRecord?
        func save(_ item: AcuityPlanRecord)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanRecordStore: AcuityPlanRecordStore {
        var items: [String: AcuityPlanRecord]
        var order: [String]

        init(items: [String: AcuityPlanRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanRecord) {
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

        func list() -> [AcuityPlanRecord] {
            var out: [AcuityPlanRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanRecordStore() -> any AcuityPlanRecordStore {
        return MemoryAcuityPlanRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanRecordStore: AcuityPlanRecordStore {
        var inner: MemoryAcuityPlanRecordStore
        var cache: TTLCache<AcuityPlanRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanRecordStore, cache: TTLCache<AcuityPlanRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanRecord? {
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

        func save(_ item: AcuityPlanRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanRecord] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanRecordStore(_ inner: MemoryAcuityPlanRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanRecordStore {
        return CachedAcuityPlanRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan records. Empty fields match all.
    final class AcuityPlanRecordQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanRecord]) -> [AcuityPlanRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanRecords(_ store: any AcuityPlanRecordStore, query: AcuityPlanRecordQuery) -> [AcuityPlanRecord] {
        return query.apply(store.list())
    }
}
