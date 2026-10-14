import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff records by code.
    protocol HandoffRecordStore {
        func find(_ code: String) -> HandoffRecord?
        func save(_ item: HandoffRecord)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffRecordStore: HandoffRecordStore {
        var items: [String: HandoffRecord]
        var order: [String]

        init(items: [String: HandoffRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffRecord) {
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

        func list() -> [HandoffRecord] {
            var out: [HandoffRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffRecordStore() -> any HandoffRecordStore {
        return MemoryHandoffRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffRecordStore: HandoffRecordStore {
        var inner: MemoryHandoffRecordStore
        var cache: TTLCache<HandoffRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffRecordStore, cache: TTLCache<HandoffRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffRecord? {
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

        func save(_ item: HandoffRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffRecord] {
            return inner.list()
        }
    }

    static func newCachedHandoffRecordStore(_ inner: MemoryHandoffRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffRecordStore {
        return CachedHandoffRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff records. Empty fields match all.
    final class HandoffRecordQuery {
        var facility: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffRecord]) -> [HandoffRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffRecords(_ store: any HandoffRecordStore, query: HandoffRecordQuery) -> [HandoffRecord] {
        return query.apply(store.list())
    }
}
