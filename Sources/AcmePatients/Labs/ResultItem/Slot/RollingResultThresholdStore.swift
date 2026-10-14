import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling result thresholds by code.
    protocol RollingResultThresholdStore {
        func find(_ code: String) -> RollingResultThreshold?
        func save(_ item: RollingResultThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RollingResultThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingResultThresholdStore: RollingResultThresholdStore {
        var items: [String: RollingResultThreshold]
        var order: [String]

        init(items: [String: RollingResultThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingResultThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingResultThreshold) {
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

        func list() -> [RollingResultThreshold] {
            var out: [RollingResultThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingResultThresholdStore() -> any RollingResultThresholdStore {
        return MemoryRollingResultThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingResultThresholdStore: RollingResultThresholdStore {
        var inner: MemoryRollingResultThresholdStore
        var cache: TTLCache<RollingResultThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingResultThresholdStore, cache: TTLCache<RollingResultThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingResultThreshold? {
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

        func save(_ item: RollingResultThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingResultThreshold] {
            return inner.list()
        }
    }

    static func newCachedRollingResultThresholdStore(_ inner: MemoryRollingResultThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingResultThresholdStore {
        return CachedRollingResultThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling result thresholds. Empty fields match all.
    final class RollingResultThresholdQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingResultThreshold) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RollingResultThreshold]) -> [RollingResultThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingResultThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingResultThresholds(_ store: any RollingResultThresholdStore, query: RollingResultThresholdQuery) -> [RollingResultThreshold] {
        return query.apply(store.list())
    }
}
