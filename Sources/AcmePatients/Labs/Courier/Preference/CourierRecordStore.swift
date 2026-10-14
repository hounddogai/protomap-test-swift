import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier records by code.
    protocol CourierRecordStore {
        func find(_ code: String) -> CourierRecord?
        func save(_ item: CourierRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CourierRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierRecordStore: CourierRecordStore {
        var items: [String: CourierRecord]
        var order: [String]

        init(items: [String: CourierRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierRecord) {
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

        func list() -> [CourierRecord] {
            var out: [CourierRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierRecordStore() -> any CourierRecordStore {
        return MemoryCourierRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierRecordStore: CourierRecordStore {
        var inner: MemoryCourierRecordStore
        var cache: TTLCache<CourierRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierRecordStore, cache: TTLCache<CourierRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierRecord? {
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

        func save(_ item: CourierRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierRecord] {
            return inner.list()
        }
    }

    static func newCachedCourierRecordStore(_ inner: MemoryCourierRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierRecordStore {
        return CachedCourierRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier records. Empty fields match all.
    final class CourierRecordQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierRecord) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierRecord]) -> [CourierRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierRecords(_ store: any CourierRecordStore, query: CourierRecordQuery) -> [CourierRecord] {
        return query.apply(store.list())
    }
}
