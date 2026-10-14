import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation schedules by code.
    protocol RevocationScheduleStore {
        func find(_ code: String) -> RevocationSchedule?
        func save(_ item: RevocationSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationScheduleStore: RevocationScheduleStore {
        var items: [String: RevocationSchedule]
        var order: [String]

        init(items: [String: RevocationSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationSchedule) {
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

        func list() -> [RevocationSchedule] {
            var out: [RevocationSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationScheduleStore() -> any RevocationScheduleStore {
        return MemoryRevocationScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationScheduleStore: RevocationScheduleStore {
        var inner: MemoryRevocationScheduleStore
        var cache: TTLCache<RevocationSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationScheduleStore, cache: TTLCache<RevocationSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationSchedule? {
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

        func save(_ item: RevocationSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationSchedule] {
            return inner.list()
        }
    }

    static func newCachedRevocationScheduleStore(_ inner: MemoryRevocationScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationScheduleStore {
        return CachedRevocationScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation schedules. Empty fields match all.
    final class RevocationScheduleQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationSchedule]) -> [RevocationSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationSchedules(_ store: any RevocationScheduleStore, query: RevocationScheduleQuery) -> [RevocationSchedule] {
        return query.apply(store.list())
    }
}
