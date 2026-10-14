import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol records by code.
    protocol CareProtocolRecordStore {
        func find(_ code: String) -> CareProtocolRecord?
        func save(_ item: CareProtocolRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolRecordStore: CareProtocolRecordStore {
        var items: [String: CareProtocolRecord]
        var order: [String]

        init(items: [String: CareProtocolRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolRecord) {
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

        func list() -> [CareProtocolRecord] {
            var out: [CareProtocolRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolRecordStore() -> any CareProtocolRecordStore {
        return MemoryCareProtocolRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolRecordStore: CareProtocolRecordStore {
        var inner: MemoryCareProtocolRecordStore
        var cache: TTLCache<CareProtocolRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolRecordStore, cache: TTLCache<CareProtocolRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolRecord? {
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

        func save(_ item: CareProtocolRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolRecord] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolRecordStore(_ inner: MemoryCareProtocolRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolRecordStore {
        return CachedCareProtocolRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol records. Empty fields match all.
    final class CareProtocolRecordQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolRecord]) -> [CareProtocolRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolRecords(_ store: any CareProtocolRecordStore, query: CareProtocolRecordQuery) -> [CareProtocolRecord] {
        return query.apply(store.list())
    }
}
