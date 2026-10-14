import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict overtime overrides by code.
    protocol StrictOvertimeOverrideStore {
        func find(_ code: String) -> StrictOvertimeOverride?
        func save(_ item: StrictOvertimeOverride)
        func remove(_ code: String) -> Bool
        func list() -> [StrictOvertimeOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictOvertimeOverrideStore: StrictOvertimeOverrideStore {
        var items: [String: StrictOvertimeOverride]
        var order: [String]

        init(items: [String: StrictOvertimeOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictOvertimeOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictOvertimeOverride) {
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

        func list() -> [StrictOvertimeOverride] {
            var out: [StrictOvertimeOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictOvertimeOverrideStore() -> any StrictOvertimeOverrideStore {
        return MemoryStrictOvertimeOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictOvertimeOverrideStore: StrictOvertimeOverrideStore {
        var inner: MemoryStrictOvertimeOverrideStore
        var cache: TTLCache<StrictOvertimeOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictOvertimeOverrideStore, cache: TTLCache<StrictOvertimeOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictOvertimeOverride? {
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

        func save(_ item: StrictOvertimeOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictOvertimeOverride] {
            return inner.list()
        }
    }

    static func newCachedStrictOvertimeOverrideStore(_ inner: MemoryStrictOvertimeOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictOvertimeOverrideStore {
        return CachedStrictOvertimeOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict overtime overrides. Empty fields match all.
    final class StrictOvertimeOverrideQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictOvertimeOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [StrictOvertimeOverride]) -> [StrictOvertimeOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictOvertimeOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictOvertimeOverrides(_ store: any StrictOvertimeOverrideStore, query: StrictOvertimeOverrideQuery) -> [StrictOvertimeOverride] {
        return query.apply(store.list())
    }
}
