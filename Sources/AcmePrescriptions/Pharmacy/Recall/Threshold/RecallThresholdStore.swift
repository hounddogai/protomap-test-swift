import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall thresholds by code.
    protocol RecallThresholdStore {
        func find(_ code: String) -> RecallThreshold?
        func save(_ item: RecallThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RecallThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallThresholdStore: RecallThresholdStore {
        var items: [String: RecallThreshold]
        var order: [String]

        init(items: [String: RecallThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallThreshold) {
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

        func list() -> [RecallThreshold] {
            var out: [RecallThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallThresholdStore() -> any RecallThresholdStore {
        return MemoryRecallThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallThresholdStore: RecallThresholdStore {
        var inner: MemoryRecallThresholdStore
        var cache: TTLCache<RecallThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallThresholdStore, cache: TTLCache<RecallThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallThreshold? {
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

        func save(_ item: RecallThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallThreshold] {
            return inner.list()
        }
    }

    static func newCachedRecallThresholdStore(_ inner: MemoryRecallThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallThresholdStore {
        return CachedRecallThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall thresholds. Empty fields match all.
    final class RecallThresholdQuery {
        var facility: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRatio: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallThreshold) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [RecallThreshold]) -> [RecallThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallThresholds(_ store: any RecallThresholdStore, query: RecallThresholdQuery) -> [RecallThreshold] {
        return query.apply(store.list())
    }
}
