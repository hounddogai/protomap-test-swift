import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional accession schedules by code.
    protocol RegionalAccessionScheduleStore {
        func find(_ code: String) -> RegionalAccessionSchedule?
        func save(_ item: RegionalAccessionSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAccessionSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAccessionScheduleStore: RegionalAccessionScheduleStore {
        var items: [String: RegionalAccessionSchedule]
        var order: [String]

        init(items: [String: RegionalAccessionSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAccessionSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAccessionSchedule) {
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

        func list() -> [RegionalAccessionSchedule] {
            var out: [RegionalAccessionSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAccessionScheduleStore() -> any RegionalAccessionScheduleStore {
        return MemoryRegionalAccessionScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAccessionScheduleStore: RegionalAccessionScheduleStore {
        var inner: MemoryRegionalAccessionScheduleStore
        var cache: TTLCache<RegionalAccessionSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAccessionScheduleStore, cache: TTLCache<RegionalAccessionSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAccessionSchedule? {
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

        func save(_ item: RegionalAccessionSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAccessionSchedule] {
            return inner.list()
        }
    }

    static func newCachedRegionalAccessionScheduleStore(_ inner: MemoryRegionalAccessionScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAccessionScheduleStore {
        return CachedRegionalAccessionScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional accession schedules. Empty fields match all.
    final class RegionalAccessionScheduleQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAccessionSchedule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [RegionalAccessionSchedule]) -> [RegionalAccessionSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAccessionSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAccessionSchedules(_ store: any RegionalAccessionScheduleStore, query: RegionalAccessionScheduleQuery) -> [RegionalAccessionSchedule] {
        return query.apply(store.list())
    }
}
