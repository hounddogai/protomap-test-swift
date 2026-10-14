import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default formulary records by code.
    protocol DefaultFormularyRecordStore {
        func find(_ code: String) -> DefaultFormularyRecord?
        func save(_ item: DefaultFormularyRecord)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultFormularyRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultFormularyRecordStore: DefaultFormularyRecordStore {
        var items: [String: DefaultFormularyRecord]
        var order: [String]

        init(items: [String: DefaultFormularyRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultFormularyRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultFormularyRecord) {
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

        func list() -> [DefaultFormularyRecord] {
            var out: [DefaultFormularyRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultFormularyRecordStore() -> any DefaultFormularyRecordStore {
        return MemoryDefaultFormularyRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultFormularyRecordStore: DefaultFormularyRecordStore {
        var inner: MemoryDefaultFormularyRecordStore
        var cache: TTLCache<DefaultFormularyRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultFormularyRecordStore, cache: TTLCache<DefaultFormularyRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultFormularyRecord? {
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

        func save(_ item: DefaultFormularyRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultFormularyRecord] {
            return inner.list()
        }
    }

    static func newCachedDefaultFormularyRecordStore(_ inner: MemoryDefaultFormularyRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultFormularyRecordStore {
        return CachedDefaultFormularyRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default formulary records. Empty fields match all.
    final class DefaultFormularyRecordQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultFormularyRecord) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultFormularyRecord]) -> [DefaultFormularyRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultFormularyRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultFormularyRecords(_ store: any DefaultFormularyRecordStore, query: DefaultFormularyRecordQuery) -> [DefaultFormularyRecord] {
        return query.apply(store.list())
    }
}
