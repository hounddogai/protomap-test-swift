import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient interaction schedules by code.
    protocol LenientInteractionScheduleStore {
        func find(_ code: String) -> LenientInteractionSchedule?
        func save(_ item: LenientInteractionSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LenientInteractionSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientInteractionScheduleStore: LenientInteractionScheduleStore {
        var items: [String: LenientInteractionSchedule]
        var order: [String]

        init(items: [String: LenientInteractionSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientInteractionSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientInteractionSchedule) {
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

        func list() -> [LenientInteractionSchedule] {
            var out: [LenientInteractionSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientInteractionScheduleStore() -> any LenientInteractionScheduleStore {
        return MemoryLenientInteractionScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientInteractionScheduleStore: LenientInteractionScheduleStore {
        var inner: MemoryLenientInteractionScheduleStore
        var cache: TTLCache<LenientInteractionSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientInteractionScheduleStore, cache: TTLCache<LenientInteractionSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientInteractionSchedule? {
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

        func save(_ item: LenientInteractionSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientInteractionSchedule] {
            return inner.list()
        }
    }

    static func newCachedLenientInteractionScheduleStore(_ inner: MemoryLenientInteractionScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientInteractionScheduleStore {
        return CachedLenientInteractionScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient interaction schedules. Empty fields match all.
    final class LenientInteractionScheduleQuery {
        var source: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCopay: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientInteractionSchedule) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [LenientInteractionSchedule]) -> [LenientInteractionSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientInteractionSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientInteractionSchedules(_ store: any LenientInteractionScheduleStore, query: LenientInteractionScheduleQuery) -> [LenientInteractionSchedule] {
        return query.apply(store.list())
    }
}
