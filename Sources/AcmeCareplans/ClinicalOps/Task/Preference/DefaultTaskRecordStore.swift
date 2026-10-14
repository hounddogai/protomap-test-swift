import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default task records by code.
    protocol DefaultTaskRecordStore {
        func find(_ code: String) -> DefaultTaskRecord?
        func save(_ item: DefaultTaskRecord)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultTaskRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultTaskRecordStore: DefaultTaskRecordStore {
        var items: [String: DefaultTaskRecord]
        var order: [String]

        init(items: [String: DefaultTaskRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultTaskRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultTaskRecord) {
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

        func list() -> [DefaultTaskRecord] {
            var out: [DefaultTaskRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultTaskRecordStore() -> any DefaultTaskRecordStore {
        return MemoryDefaultTaskRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultTaskRecordStore: DefaultTaskRecordStore {
        var inner: MemoryDefaultTaskRecordStore
        var cache: TTLCache<DefaultTaskRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultTaskRecordStore, cache: TTLCache<DefaultTaskRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultTaskRecord? {
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

        func save(_ item: DefaultTaskRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultTaskRecord] {
            return inner.list()
        }
    }

    static func newCachedDefaultTaskRecordStore(_ inner: MemoryDefaultTaskRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultTaskRecordStore {
        return CachedDefaultTaskRecordStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default task records. Empty fields match all.
    final class DefaultTaskRecordQuery {
        var region: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultTaskRecord) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultTaskRecord]) -> [DefaultTaskRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultTaskRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultTaskRecords(_ store: any DefaultTaskRecordStore, query: DefaultTaskRecordQuery) -> [DefaultTaskRecord] {
        return query.apply(store.list())
    }
}
