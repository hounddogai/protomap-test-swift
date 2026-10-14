import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary priority thresholds by code.
    protocol PrimaryPriorityThresholdStore {
        func find(_ code: String) -> PrimaryPriorityThreshold?
        func save(_ item: PrimaryPriorityThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryPriorityThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryPriorityThresholdStore: PrimaryPriorityThresholdStore {
        var items: [String: PrimaryPriorityThreshold]
        var order: [String]

        init(items: [String: PrimaryPriorityThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryPriorityThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryPriorityThreshold) {
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

        func list() -> [PrimaryPriorityThreshold] {
            var out: [PrimaryPriorityThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryPriorityThresholdStore() -> any PrimaryPriorityThresholdStore {
        return MemoryPrimaryPriorityThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryPriorityThresholdStore: PrimaryPriorityThresholdStore {
        var inner: MemoryPrimaryPriorityThresholdStore
        var cache: TTLCache<PrimaryPriorityThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryPriorityThresholdStore, cache: TTLCache<PrimaryPriorityThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryPriorityThreshold? {
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

        func save(_ item: PrimaryPriorityThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryPriorityThreshold] {
            return inner.list()
        }
    }

    static func newCachedPrimaryPriorityThresholdStore(_ inner: MemoryPrimaryPriorityThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryPriorityThresholdStore {
        return CachedPrimaryPriorityThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary priority thresholds. Empty fields match all.
    final class PrimaryPriorityThresholdQuery {
        var source: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryPriorityThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [PrimaryPriorityThreshold]) -> [PrimaryPriorityThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryPriorityThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryPriorityThresholds(_ store: any PrimaryPriorityThresholdStore, query: PrimaryPriorityThresholdQuery) -> [PrimaryPriorityThreshold] {
        return query.apply(store.list())
    }
}
