import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary schedules by code.
    protocol FormularyScheduleStore {
        func find(_ code: String) -> FormularySchedule?
        func save(_ item: FormularySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [FormularySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyScheduleStore: FormularyScheduleStore {
        var items: [String: FormularySchedule]
        var order: [String]

        init(items: [String: FormularySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularySchedule) {
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

        func list() -> [FormularySchedule] {
            var out: [FormularySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyScheduleStore() -> any FormularyScheduleStore {
        return MemoryFormularyScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyScheduleStore: FormularyScheduleStore {
        var inner: MemoryFormularyScheduleStore
        var cache: TTLCache<FormularySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyScheduleStore, cache: TTLCache<FormularySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularySchedule? {
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

        func save(_ item: FormularySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularySchedule] {
            return inner.list()
        }
    }

    static func newCachedFormularyScheduleStore(_ inner: MemoryFormularyScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyScheduleStore {
        return CachedFormularyScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary schedules. Empty fields match all.
    final class FormularyScheduleQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularySchedule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularySchedule]) -> [FormularySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularySchedules(_ store: any FormularyScheduleStore, query: FormularyScheduleQuery) -> [FormularySchedule] {
        return query.apply(store.list())
    }
}
