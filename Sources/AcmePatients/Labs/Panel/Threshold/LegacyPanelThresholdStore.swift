import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy panel thresholds by code.
    protocol LegacyPanelThresholdStore {
        func find(_ code: String) -> LegacyPanelThreshold?
        func save(_ item: LegacyPanelThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyPanelThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyPanelThresholdStore: LegacyPanelThresholdStore {
        var items: [String: LegacyPanelThreshold]
        var order: [String]

        init(items: [String: LegacyPanelThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyPanelThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyPanelThreshold) {
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

        func list() -> [LegacyPanelThreshold] {
            var out: [LegacyPanelThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyPanelThresholdStore() -> any LegacyPanelThresholdStore {
        return MemoryLegacyPanelThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyPanelThresholdStore: LegacyPanelThresholdStore {
        var inner: MemoryLegacyPanelThresholdStore
        var cache: TTLCache<LegacyPanelThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyPanelThresholdStore, cache: TTLCache<LegacyPanelThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyPanelThreshold? {
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

        func save(_ item: LegacyPanelThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyPanelThreshold] {
            return inner.list()
        }
    }

    static func newCachedLegacyPanelThresholdStore(_ inner: MemoryLegacyPanelThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyPanelThresholdStore {
        return CachedLegacyPanelThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy panel thresholds. Empty fields match all.
    final class LegacyPanelThresholdQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyPanelThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyPanelThreshold]) -> [LegacyPanelThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyPanelThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyPanelThresholds(_ store: any LegacyPanelThresholdStore, query: LegacyPanelThresholdQuery) -> [LegacyPanelThreshold] {
        return query.apply(store.list())
    }
}
