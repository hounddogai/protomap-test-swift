import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense thresholds by code.
    protocol DispenseThresholdStore {
        func find(_ code: String) -> DispenseThreshold?
        func save(_ item: DispenseThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseThresholdStore: DispenseThresholdStore {
        var items: [String: DispenseThreshold]
        var order: [String]

        init(items: [String: DispenseThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseThreshold) {
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

        func list() -> [DispenseThreshold] {
            var out: [DispenseThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseThresholdStore() -> any DispenseThresholdStore {
        return MemoryDispenseThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseThresholdStore: DispenseThresholdStore {
        var inner: MemoryDispenseThresholdStore
        var cache: TTLCache<DispenseThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseThresholdStore, cache: TTLCache<DispenseThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseThreshold? {
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

        func save(_ item: DispenseThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseThreshold] {
            return inner.list()
        }
    }

    static func newCachedDispenseThresholdStore(_ inner: MemoryDispenseThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseThresholdStore {
        return CachedDispenseThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense thresholds. Empty fields match all.
    final class DispenseThresholdQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseThreshold]) -> [DispenseThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseThresholds(_ store: any DispenseThresholdStore, query: DispenseThresholdQuery) -> [DispenseThreshold] {
        return query.apply(store.list())
    }
}
