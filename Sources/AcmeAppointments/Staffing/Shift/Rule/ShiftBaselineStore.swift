import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift baselines by code.
    protocol ShiftBaselineStore {
        func find(_ code: String) -> ShiftBaseline?
        func save(_ item: ShiftBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftBaselineStore: ShiftBaselineStore {
        var items: [String: ShiftBaseline]
        var order: [String]

        init(items: [String: ShiftBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftBaseline) {
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

        func list() -> [ShiftBaseline] {
            var out: [ShiftBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftBaselineStore() -> any ShiftBaselineStore {
        return MemoryShiftBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftBaselineStore: ShiftBaselineStore {
        var inner: MemoryShiftBaselineStore
        var cache: TTLCache<ShiftBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftBaselineStore, cache: TTLCache<ShiftBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftBaseline? {
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

        func save(_ item: ShiftBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftBaseline] {
            return inner.list()
        }
    }

    static func newCachedShiftBaselineStore(_ inner: MemoryShiftBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftBaselineStore {
        return CachedShiftBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift baselines. Empty fields match all.
    final class ShiftBaselineQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ShiftBaseline]) -> [ShiftBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftBaselines(_ store: any ShiftBaselineStore, query: ShiftBaselineQuery) -> [ShiftBaseline] {
        return query.apply(store.list())
    }
}
