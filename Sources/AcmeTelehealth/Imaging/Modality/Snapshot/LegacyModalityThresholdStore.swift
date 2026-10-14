import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy modality thresholds by code.
    protocol LegacyModalityThresholdStore {
        func find(_ code: String) -> LegacyModalityThreshold?
        func save(_ item: LegacyModalityThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyModalityThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyModalityThresholdStore: LegacyModalityThresholdStore {
        var items: [String: LegacyModalityThreshold]
        var order: [String]

        init(items: [String: LegacyModalityThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyModalityThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyModalityThreshold) {
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

        func list() -> [LegacyModalityThreshold] {
            var out: [LegacyModalityThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyModalityThresholdStore() -> any LegacyModalityThresholdStore {
        return MemoryLegacyModalityThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyModalityThresholdStore: LegacyModalityThresholdStore {
        var inner: MemoryLegacyModalityThresholdStore
        var cache: TTLCache<LegacyModalityThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyModalityThresholdStore, cache: TTLCache<LegacyModalityThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyModalityThreshold? {
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

        func save(_ item: LegacyModalityThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyModalityThreshold] {
            return inner.list()
        }
    }

    static func newCachedLegacyModalityThresholdStore(_ inner: MemoryLegacyModalityThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyModalityThresholdStore {
        return CachedLegacyModalityThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy modality thresholds. Empty fields match all.
    final class LegacyModalityThresholdQuery {
        var source: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyModalityThreshold) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyModalityThreshold]) -> [LegacyModalityThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyModalityThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyModalityThresholds(_ store: any LegacyModalityThresholdStore, query: LegacyModalityThresholdQuery) -> [LegacyModalityThreshold] {
        return query.apply(store.list())
    }
}
