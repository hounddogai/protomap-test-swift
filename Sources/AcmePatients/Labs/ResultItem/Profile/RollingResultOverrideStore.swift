import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling result overrides by code.
    protocol RollingResultOverrideStore {
        func find(_ code: String) -> RollingResultOverride?
        func save(_ item: RollingResultOverride)
        func remove(_ code: String) -> Bool
        func list() -> [RollingResultOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingResultOverrideStore: RollingResultOverrideStore {
        var items: [String: RollingResultOverride]
        var order: [String]

        init(items: [String: RollingResultOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingResultOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingResultOverride) {
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

        func list() -> [RollingResultOverride] {
            var out: [RollingResultOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingResultOverrideStore() -> any RollingResultOverrideStore {
        return MemoryRollingResultOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingResultOverrideStore: RollingResultOverrideStore {
        var inner: MemoryRollingResultOverrideStore
        var cache: TTLCache<RollingResultOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingResultOverrideStore, cache: TTLCache<RollingResultOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingResultOverride? {
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

        func save(_ item: RollingResultOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingResultOverride] {
            return inner.list()
        }
    }

    static func newCachedRollingResultOverrideStore(_ inner: MemoryRollingResultOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingResultOverrideStore {
        return CachedRollingResultOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling result overrides. Empty fields match all.
    final class RollingResultOverrideQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingResultOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingResultOverride]) -> [RollingResultOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingResultOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingResultOverrides(_ store: any RollingResultOverrideStore, query: RollingResultOverrideQuery) -> [RollingResultOverride] {
        return query.apply(store.list())
    }
}
