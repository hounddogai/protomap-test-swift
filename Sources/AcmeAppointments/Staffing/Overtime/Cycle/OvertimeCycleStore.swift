import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime cycles by code.
    protocol OvertimeCycleStore {
        func find(_ code: String) -> OvertimeCycle?
        func save(_ item: OvertimeCycle)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeCycleStore: OvertimeCycleStore {
        var items: [String: OvertimeCycle]
        var order: [String]

        init(items: [String: OvertimeCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeCycle) {
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

        func list() -> [OvertimeCycle] {
            var out: [OvertimeCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeCycleStore() -> any OvertimeCycleStore {
        return MemoryOvertimeCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeCycleStore: OvertimeCycleStore {
        var inner: MemoryOvertimeCycleStore
        var cache: TTLCache<OvertimeCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeCycleStore, cache: TTLCache<OvertimeCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeCycle? {
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

        func save(_ item: OvertimeCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeCycle] {
            return inner.list()
        }
    }

    static func newCachedOvertimeCycleStore(_ inner: MemoryOvertimeCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeCycleStore {
        return CachedOvertimeCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime cycles. Empty fields match all.
    final class OvertimeCycleQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeCycle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeCycle]) -> [OvertimeCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeCycles(_ store: any OvertimeCycleStore, query: OvertimeCycleQuery) -> [OvertimeCycle] {
        return query.apply(store.list())
    }
}
