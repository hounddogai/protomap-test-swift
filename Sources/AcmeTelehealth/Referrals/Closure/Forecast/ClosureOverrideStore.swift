import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure overrides by code.
    protocol ClosureOverrideStore {
        func find(_ code: String) -> ClosureOverride?
        func save(_ item: ClosureOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureOverrideStore: ClosureOverrideStore {
        var items: [String: ClosureOverride]
        var order: [String]

        init(items: [String: ClosureOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureOverride) {
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

        func list() -> [ClosureOverride] {
            var out: [ClosureOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureOverrideStore() -> any ClosureOverrideStore {
        return MemoryClosureOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureOverrideStore: ClosureOverrideStore {
        var inner: MemoryClosureOverrideStore
        var cache: TTLCache<ClosureOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureOverrideStore, cache: TTLCache<ClosureOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureOverride? {
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

        func save(_ item: ClosureOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureOverride] {
            return inner.list()
        }
    }

    static func newCachedClosureOverrideStore(_ inner: MemoryClosureOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureOverrideStore {
        return CachedClosureOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure overrides. Empty fields match all.
    final class ClosureOverrideQuery {
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

        func matches(_ item: ClosureOverride) -> Bool {
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

        func apply(_ items: [ClosureOverride]) -> [ClosureOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureOverrides(_ store: any ClosureOverrideStore, query: ClosureOverrideQuery) -> [ClosureOverride] {
        return query.apply(store.list())
    }
}
