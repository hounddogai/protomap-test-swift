import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial thresholds by code.
    protocol DenialThresholdStore {
        func find(_ code: String) -> DenialThreshold?
        func save(_ item: DenialThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [DenialThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialThresholdStore: DenialThresholdStore {
        var items: [String: DenialThreshold]
        var order: [String]

        init(items: [String: DenialThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialThreshold) {
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

        func list() -> [DenialThreshold] {
            var out: [DenialThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialThresholdStore() -> any DenialThresholdStore {
        return MemoryDenialThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialThresholdStore: DenialThresholdStore {
        var inner: MemoryDenialThresholdStore
        var cache: TTLCache<DenialThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialThresholdStore, cache: TTLCache<DenialThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialThreshold? {
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

        func save(_ item: DenialThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialThreshold] {
            return inner.list()
        }
    }

    static func newCachedDenialThresholdStore(_ inner: MemoryDenialThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialThresholdStore {
        return CachedDenialThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial thresholds. Empty fields match all.
    final class DenialThresholdQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialThreshold]) -> [DenialThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialThresholds(_ store: any DenialThresholdStore, query: DenialThresholdQuery) -> [DenialThreshold] {
        return query.apply(store.list())
    }
}
