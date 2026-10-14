import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier ledgers by code.
    protocol CourierLedgerStore {
        func find(_ code: String) -> CourierLedger?
        func save(_ item: CourierLedger)
        func remove(_ code: String) -> Bool
        func list() -> [CourierLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierLedgerStore: CourierLedgerStore {
        var items: [String: CourierLedger]
        var order: [String]

        init(items: [String: CourierLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierLedger) {
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

        func list() -> [CourierLedger] {
            var out: [CourierLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierLedgerStore() -> any CourierLedgerStore {
        return MemoryCourierLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierLedgerStore: CourierLedgerStore {
        var inner: MemoryCourierLedgerStore
        var cache: TTLCache<CourierLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierLedgerStore, cache: TTLCache<CourierLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierLedger? {
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

        func save(_ item: CourierLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierLedger] {
            return inner.list()
        }
    }

    static func newCachedCourierLedgerStore(_ inner: MemoryCourierLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierLedgerStore {
        return CachedCourierLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier ledgers. Empty fields match all.
    final class CourierLedgerQuery {
        var channel: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMargin: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierLedger]) -> [CourierLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierLedgers(_ store: any CourierLedgerStore, query: CourierLedgerQuery) -> [CourierLedger] {
        return query.apply(store.list())
    }
}
