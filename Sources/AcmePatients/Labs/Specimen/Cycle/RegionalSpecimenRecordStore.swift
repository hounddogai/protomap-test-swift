import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional specimen records by code.
    protocol RegionalSpecimenRecordStore {
        func find(_ code: String) -> RegionalSpecimenRecord?
        func save(_ item: RegionalSpecimenRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSpecimenRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSpecimenRecordStore: RegionalSpecimenRecordStore {
        var items: [String: RegionalSpecimenRecord]
        var order: [String]

        init(items: [String: RegionalSpecimenRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSpecimenRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSpecimenRecord) {
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

        func list() -> [RegionalSpecimenRecord] {
            var out: [RegionalSpecimenRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSpecimenRecordStore() -> any RegionalSpecimenRecordStore {
        return MemoryRegionalSpecimenRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSpecimenRecordStore: RegionalSpecimenRecordStore {
        var inner: MemoryRegionalSpecimenRecordStore
        var cache: TTLCache<RegionalSpecimenRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSpecimenRecordStore, cache: TTLCache<RegionalSpecimenRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSpecimenRecord? {
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

        func save(_ item: RegionalSpecimenRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSpecimenRecord] {
            return inner.list()
        }
    }

    static func newCachedRegionalSpecimenRecordStore(_ inner: MemoryRegionalSpecimenRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSpecimenRecordStore {
        return CachedRegionalSpecimenRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional specimen records. Empty fields match all.
    final class RegionalSpecimenRecordQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSpecimenRecord) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSpecimenRecord]) -> [RegionalSpecimenRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSpecimenRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSpecimenRecords(_ store: any RegionalSpecimenRecordStore, query: RegionalSpecimenRecordQuery) -> [RegionalSpecimenRecord] {
        return query.apply(store.list())
    }
}
