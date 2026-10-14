import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy accession thresholds by code.
    protocol LegacyAccessionThresholdStore {
        func find(_ code: String) -> LegacyAccessionThreshold?
        func save(_ item: LegacyAccessionThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAccessionThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAccessionThresholdStore: LegacyAccessionThresholdStore {
        var items: [String: LegacyAccessionThreshold]
        var order: [String]

        init(items: [String: LegacyAccessionThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAccessionThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAccessionThreshold) {
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

        func list() -> [LegacyAccessionThreshold] {
            var out: [LegacyAccessionThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAccessionThresholdStore() -> any LegacyAccessionThresholdStore {
        return MemoryLegacyAccessionThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAccessionThresholdStore: LegacyAccessionThresholdStore {
        var inner: MemoryLegacyAccessionThresholdStore
        var cache: TTLCache<LegacyAccessionThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAccessionThresholdStore, cache: TTLCache<LegacyAccessionThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAccessionThreshold? {
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

        func save(_ item: LegacyAccessionThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAccessionThreshold] {
            return inner.list()
        }
    }

    static func newCachedLegacyAccessionThresholdStore(_ inner: MemoryLegacyAccessionThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAccessionThresholdStore {
        return CachedLegacyAccessionThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy accession thresholds. Empty fields match all.
    final class LegacyAccessionThresholdQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAccessionThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAccessionThreshold]) -> [LegacyAccessionThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAccessionThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAccessionThresholds(_ store: any LegacyAccessionThresholdStore, query: LegacyAccessionThresholdQuery) -> [LegacyAccessionThreshold] {
        return query.apply(store.list())
    }
}
