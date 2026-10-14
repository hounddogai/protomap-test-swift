import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default interaction schedules by code.
    protocol DefaultInteractionScheduleStore {
        func find(_ code: String) -> DefaultInteractionSchedule?
        func save(_ item: DefaultInteractionSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultInteractionSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultInteractionScheduleStore: DefaultInteractionScheduleStore {
        var items: [String: DefaultInteractionSchedule]
        var order: [String]

        init(items: [String: DefaultInteractionSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultInteractionSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultInteractionSchedule) {
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

        func list() -> [DefaultInteractionSchedule] {
            var out: [DefaultInteractionSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultInteractionScheduleStore() -> any DefaultInteractionScheduleStore {
        return MemoryDefaultInteractionScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultInteractionScheduleStore: DefaultInteractionScheduleStore {
        var inner: MemoryDefaultInteractionScheduleStore
        var cache: TTLCache<DefaultInteractionSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultInteractionScheduleStore, cache: TTLCache<DefaultInteractionSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultInteractionSchedule? {
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

        func save(_ item: DefaultInteractionSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultInteractionSchedule] {
            return inner.list()
        }
    }

    static func newCachedDefaultInteractionScheduleStore(_ inner: MemoryDefaultInteractionScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultInteractionScheduleStore {
        return CachedDefaultInteractionScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default interaction schedules. Empty fields match all.
    final class DefaultInteractionScheduleQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultInteractionSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultInteractionSchedule]) -> [DefaultInteractionSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultInteractionSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultInteractionSchedules(_ store: any DefaultInteractionScheduleStore, query: DefaultInteractionScheduleQuery) -> [DefaultInteractionSchedule] {
        return query.apply(store.list())
    }
}
