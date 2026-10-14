import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime baselines by code.
    protocol OvertimeBaselineStore {
        func find(_ code: String) -> OvertimeBaseline?
        func save(_ item: OvertimeBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeBaselineStore: OvertimeBaselineStore {
        var items: [String: OvertimeBaseline]
        var order: [String]

        init(items: [String: OvertimeBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeBaseline) {
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

        func list() -> [OvertimeBaseline] {
            var out: [OvertimeBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeBaselineStore() -> any OvertimeBaselineStore {
        return MemoryOvertimeBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeBaselineStore: OvertimeBaselineStore {
        var inner: MemoryOvertimeBaselineStore
        var cache: TTLCache<OvertimeBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeBaselineStore, cache: TTLCache<OvertimeBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeBaseline? {
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

        func save(_ item: OvertimeBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeBaseline] {
            return inner.list()
        }
    }

    static func newCachedOvertimeBaselineStore(_ inner: MemoryOvertimeBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeBaselineStore {
        return CachedOvertimeBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime baselines. Empty fields match all.
    final class OvertimeBaselineQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [OvertimeBaseline]) -> [OvertimeBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeBaselines(_ store: any OvertimeBaselineStore, query: OvertimeBaselineQuery) -> [OvertimeBaseline] {
        return query.apply(store.list())
    }
}
