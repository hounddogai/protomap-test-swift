import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation overrides by code.
    protocol IsolationOverrideStore {
        func find(_ code: String) -> IsolationOverride?
        func save(_ item: IsolationOverride)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationOverrideStore: IsolationOverrideStore {
        var items: [String: IsolationOverride]
        var order: [String]

        init(items: [String: IsolationOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationOverride) {
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

        func list() -> [IsolationOverride] {
            var out: [IsolationOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationOverrideStore() -> any IsolationOverrideStore {
        return MemoryIsolationOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationOverrideStore: IsolationOverrideStore {
        var inner: MemoryIsolationOverrideStore
        var cache: TTLCache<IsolationOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationOverrideStore, cache: TTLCache<IsolationOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationOverride? {
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

        func save(_ item: IsolationOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationOverride] {
            return inner.list()
        }
    }

    static func newCachedIsolationOverrideStore(_ inner: MemoryIsolationOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationOverrideStore {
        return CachedIsolationOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation overrides. Empty fields match all.
    final class IsolationOverrideQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationOverride]) -> [IsolationOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationOverrides(_ store: any IsolationOverrideStore, query: IsolationOverrideQuery) -> [IsolationOverride] {
        return query.apply(store.list())
    }
}
