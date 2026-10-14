import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer schedules by code.
    protocol TransferScheduleStore {
        func find(_ code: String) -> TransferSchedule?
        func save(_ item: TransferSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [TransferSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferScheduleStore: TransferScheduleStore {
        var items: [String: TransferSchedule]
        var order: [String]

        init(items: [String: TransferSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferSchedule) {
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

        func list() -> [TransferSchedule] {
            var out: [TransferSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferScheduleStore() -> any TransferScheduleStore {
        return MemoryTransferScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferScheduleStore: TransferScheduleStore {
        var inner: MemoryTransferScheduleStore
        var cache: TTLCache<TransferSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferScheduleStore, cache: TTLCache<TransferSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferSchedule? {
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

        func save(_ item: TransferSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferSchedule] {
            return inner.list()
        }
    }

    static func newCachedTransferScheduleStore(_ inner: MemoryTransferScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferScheduleStore {
        return CachedTransferScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer schedules. Empty fields match all.
    final class TransferScheduleQuery {
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

        func matches(_ item: TransferSchedule) -> Bool {
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

        func apply(_ items: [TransferSchedule]) -> [TransferSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferSchedules(_ store: any TransferScheduleStore, query: TransferScheduleQuery) -> [TransferSchedule] {
        return query.apply(store.list())
    }
}
