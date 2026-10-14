import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result overrides by code.
    protocol ResultOverrideStore {
        func find(_ code: String) -> ResultOverride?
        func save(_ item: ResultOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ResultOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultOverrideStore: ResultOverrideStore {
        var items: [String: ResultOverride]
        var order: [String]

        init(items: [String: ResultOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultOverride) {
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

        func list() -> [ResultOverride] {
            var out: [ResultOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultOverrideStore() -> any ResultOverrideStore {
        return MemoryResultOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultOverrideStore: ResultOverrideStore {
        var inner: MemoryResultOverrideStore
        var cache: TTLCache<ResultOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultOverrideStore, cache: TTLCache<ResultOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultOverride? {
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

        func save(_ item: ResultOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultOverride] {
            return inner.list()
        }
    }

    static func newCachedResultOverrideStore(_ inner: MemoryResultOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultOverrideStore {
        return CachedResultOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result overrides. Empty fields match all.
    final class ResultOverrideQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ResultOverride]) -> [ResultOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultOverrides(_ store: any ResultOverrideStore, query: ResultOverrideQuery) -> [ResultOverride] {
        return query.apply(store.list())
    }
}
