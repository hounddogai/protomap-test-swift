import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy order set thresholds by code.
    protocol LegacyOrderSetThresholdStore {
        func find(_ code: String) -> LegacyOrderSetThreshold?
        func save(_ item: LegacyOrderSetThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyOrderSetThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyOrderSetThresholdStore: LegacyOrderSetThresholdStore {
        var items: [String: LegacyOrderSetThreshold]
        var order: [String]

        init(items: [String: LegacyOrderSetThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyOrderSetThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyOrderSetThreshold) {
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

        func list() -> [LegacyOrderSetThreshold] {
            var out: [LegacyOrderSetThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyOrderSetThresholdStore() -> any LegacyOrderSetThresholdStore {
        return MemoryLegacyOrderSetThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyOrderSetThresholdStore: LegacyOrderSetThresholdStore {
        var inner: MemoryLegacyOrderSetThresholdStore
        var cache: TTLCache<LegacyOrderSetThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyOrderSetThresholdStore, cache: TTLCache<LegacyOrderSetThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyOrderSetThreshold? {
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

        func save(_ item: LegacyOrderSetThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyOrderSetThreshold] {
            return inner.list()
        }
    }

    static func newCachedLegacyOrderSetThresholdStore(_ inner: MemoryLegacyOrderSetThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyOrderSetThresholdStore {
        return CachedLegacyOrderSetThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy order set thresholds. Empty fields match all.
    final class LegacyOrderSetThresholdQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyOrderSetThreshold) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyOrderSetThreshold]) -> [LegacyOrderSetThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyOrderSetThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyOrderSetThresholds(_ store: any LegacyOrderSetThresholdStore, query: LegacyOrderSetThresholdQuery) -> [LegacyOrderSetThreshold] {
        return query.apply(store.list())
    }
}
