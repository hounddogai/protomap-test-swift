import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary statement records by code.
    protocol PrimaryStatementRecordStore {
        func find(_ code: String) -> PrimaryStatementRecord?
        func save(_ item: PrimaryStatementRecord)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryStatementRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryStatementRecordStore: PrimaryStatementRecordStore {
        var items: [String: PrimaryStatementRecord]
        var order: [String]

        init(items: [String: PrimaryStatementRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryStatementRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryStatementRecord) {
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

        func list() -> [PrimaryStatementRecord] {
            var out: [PrimaryStatementRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryStatementRecordStore() -> any PrimaryStatementRecordStore {
        return MemoryPrimaryStatementRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryStatementRecordStore: PrimaryStatementRecordStore {
        var inner: MemoryPrimaryStatementRecordStore
        var cache: TTLCache<PrimaryStatementRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryStatementRecordStore, cache: TTLCache<PrimaryStatementRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryStatementRecord? {
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

        func save(_ item: PrimaryStatementRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryStatementRecord] {
            return inner.list()
        }
    }

    static func newCachedPrimaryStatementRecordStore(_ inner: MemoryPrimaryStatementRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryStatementRecordStore {
        return CachedPrimaryStatementRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary statement records. Empty fields match all.
    final class PrimaryStatementRecordQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryStatementRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryStatementRecord]) -> [PrimaryStatementRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryStatementRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryStatementRecords(_ store: any PrimaryStatementRecordStore, query: PrimaryStatementRecordQuery) -> [PrimaryStatementRecord] {
        return query.apply(store.list())
    }
}
