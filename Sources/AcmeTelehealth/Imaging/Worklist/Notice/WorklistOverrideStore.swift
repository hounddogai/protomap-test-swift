import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist overrides by code.
    protocol WorklistOverrideStore {
        func find(_ code: String) -> WorklistOverride?
        func save(_ item: WorklistOverride)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistOverrideStore: WorklistOverrideStore {
        var items: [String: WorklistOverride]
        var order: [String]

        init(items: [String: WorklistOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistOverride) {
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

        func list() -> [WorklistOverride] {
            var out: [WorklistOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistOverrideStore() -> any WorklistOverrideStore {
        return MemoryWorklistOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistOverrideStore: WorklistOverrideStore {
        var inner: MemoryWorklistOverrideStore
        var cache: TTLCache<WorklistOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistOverrideStore, cache: TTLCache<WorklistOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistOverride? {
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

        func save(_ item: WorklistOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistOverride] {
            return inner.list()
        }
    }

    static func newCachedWorklistOverrideStore(_ inner: MemoryWorklistOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistOverrideStore {
        return CachedWorklistOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist overrides. Empty fields match all.
    final class WorklistOverrideQuery {
        var locale: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistOverride]) -> [WorklistOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistOverrides(_ store: any WorklistOverrideStore, query: WorklistOverrideQuery) -> [WorklistOverride] {
        return query.apply(store.list())
    }
}
