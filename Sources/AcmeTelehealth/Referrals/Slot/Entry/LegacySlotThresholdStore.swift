import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy slot thresholds by code.
    protocol LegacySlotThresholdStore {
        func find(_ code: String) -> LegacySlotThreshold?
        func save(_ item: LegacySlotThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySlotThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySlotThresholdStore: LegacySlotThresholdStore {
        var items: [String: LegacySlotThreshold]
        var order: [String]

        init(items: [String: LegacySlotThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySlotThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySlotThreshold) {
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

        func list() -> [LegacySlotThreshold] {
            var out: [LegacySlotThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySlotThresholdStore() -> any LegacySlotThresholdStore {
        return MemoryLegacySlotThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySlotThresholdStore: LegacySlotThresholdStore {
        var inner: MemoryLegacySlotThresholdStore
        var cache: TTLCache<LegacySlotThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySlotThresholdStore, cache: TTLCache<LegacySlotThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySlotThreshold? {
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

        func save(_ item: LegacySlotThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySlotThreshold] {
            return inner.list()
        }
    }

    static func newCachedLegacySlotThresholdStore(_ inner: MemoryLegacySlotThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySlotThresholdStore {
        return CachedLegacySlotThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy slot thresholds. Empty fields match all.
    final class LegacySlotThresholdQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySlotThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacySlotThreshold]) -> [LegacySlotThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySlotThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySlotThresholds(_ store: any LegacySlotThresholdStore, query: LegacySlotThresholdQuery) -> [LegacySlotThreshold] {
        return query.apply(store.list())
    }
}
