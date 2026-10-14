import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task thresholds by code.
    protocol TaskThresholdStore {
        func find(_ code: String) -> TaskThreshold?
        func save(_ item: TaskThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [TaskThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskThresholdStore: TaskThresholdStore {
        var items: [String: TaskThreshold]
        var order: [String]

        init(items: [String: TaskThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskThreshold) {
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

        func list() -> [TaskThreshold] {
            var out: [TaskThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskThresholdStore() -> any TaskThresholdStore {
        return MemoryTaskThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskThresholdStore: TaskThresholdStore {
        var inner: MemoryTaskThresholdStore
        var cache: TTLCache<TaskThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskThresholdStore, cache: TTLCache<TaskThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskThreshold? {
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

        func save(_ item: TaskThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskThreshold] {
            return inner.list()
        }
    }

    static func newCachedTaskThresholdStore(_ inner: MemoryTaskThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskThresholdStore {
        return CachedTaskThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task thresholds. Empty fields match all.
    final class TaskThresholdQuery {
        var source: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRatio: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskThreshold]) -> [TaskThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskThresholds(_ store: any TaskThresholdStore, query: TaskThresholdQuery) -> [TaskThreshold] {
        return query.apply(store.list())
    }
}
