import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary panel schedules by code.
    protocol PrimaryPanelScheduleStore {
        func find(_ code: String) -> PrimaryPanelSchedule?
        func save(_ item: PrimaryPanelSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryPanelSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryPanelScheduleStore: PrimaryPanelScheduleStore {
        var items: [String: PrimaryPanelSchedule]
        var order: [String]

        init(items: [String: PrimaryPanelSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryPanelSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryPanelSchedule) {
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

        func list() -> [PrimaryPanelSchedule] {
            var out: [PrimaryPanelSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryPanelScheduleStore() -> any PrimaryPanelScheduleStore {
        return MemoryPrimaryPanelScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryPanelScheduleStore: PrimaryPanelScheduleStore {
        var inner: MemoryPrimaryPanelScheduleStore
        var cache: TTLCache<PrimaryPanelSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryPanelScheduleStore, cache: TTLCache<PrimaryPanelSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryPanelSchedule? {
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

        func save(_ item: PrimaryPanelSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryPanelSchedule] {
            return inner.list()
        }
    }

    static func newCachedPrimaryPanelScheduleStore(_ inner: MemoryPrimaryPanelScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryPanelScheduleStore {
        return CachedPrimaryPanelScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary panel schedules. Empty fields match all.
    final class PrimaryPanelScheduleQuery {
        var source: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryPanelSchedule) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryPanelSchedule]) -> [PrimaryPanelSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryPanelSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryPanelSchedules(_ store: any PrimaryPanelScheduleStore, query: PrimaryPanelScheduleQuery) -> [PrimaryPanelSchedule] {
        return query.apply(store.list())
    }
}
