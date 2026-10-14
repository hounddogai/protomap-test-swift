import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution records by code.
    protocol SubstitutionRecordStore {
        func find(_ code: String) -> SubstitutionRecord?
        func save(_ item: SubstitutionRecord)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionRecordStore: SubstitutionRecordStore {
        var items: [String: SubstitutionRecord]
        var order: [String]

        init(items: [String: SubstitutionRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionRecord) {
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

        func list() -> [SubstitutionRecord] {
            var out: [SubstitutionRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionRecordStore() -> any SubstitutionRecordStore {
        return MemorySubstitutionRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionRecordStore: SubstitutionRecordStore {
        var inner: MemorySubstitutionRecordStore
        var cache: TTLCache<SubstitutionRecord>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionRecordStore, cache: TTLCache<SubstitutionRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionRecord? {
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

        func save(_ item: SubstitutionRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionRecord] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionRecordStore(_ inner: MemorySubstitutionRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionRecordStore {
        return CachedSubstitutionRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution records. Empty fields match all.
    final class SubstitutionRecordQuery {
        var facility: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionRecord) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionRecord]) -> [SubstitutionRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionRecords(_ store: any SubstitutionRecordStore, query: SubstitutionRecordQuery) -> [SubstitutionRecord] {
        return query.apply(store.list())
    }
}
