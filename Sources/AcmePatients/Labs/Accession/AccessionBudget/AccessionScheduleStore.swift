import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession schedules by code.
    protocol AccessionScheduleStore {
        func find(_ code: String) -> AccessionSchedule?
        func save(_ item: AccessionSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionScheduleStore: AccessionScheduleStore {
        var items: [String: AccessionSchedule]
        var order: [String]

        init(items: [String: AccessionSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionSchedule) {
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

        func list() -> [AccessionSchedule] {
            var out: [AccessionSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionScheduleStore() -> any AccessionScheduleStore {
        return MemoryAccessionScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionScheduleStore: AccessionScheduleStore {
        var inner: MemoryAccessionScheduleStore
        var cache: TTLCache<AccessionSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionScheduleStore, cache: TTLCache<AccessionSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionSchedule? {
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

        func save(_ item: AccessionSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionSchedule] {
            return inner.list()
        }
    }

    static func newCachedAccessionScheduleStore(_ inner: MemoryAccessionScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionScheduleStore {
        return CachedAccessionScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession schedules. Empty fields match all.
    final class AccessionScheduleQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionSchedule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionSchedule]) -> [AccessionSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionSchedules(_ store: any AccessionScheduleStore, query: AccessionScheduleQuery) -> [AccessionSchedule] {
        return query.apply(store.list())
    }
}
