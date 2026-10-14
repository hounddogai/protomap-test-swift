import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive care gap overrides by code.
    protocol AdaptiveCareGapOverrideStore {
        func find(_ code: String) -> AdaptiveCareGapOverride?
        func save(_ item: AdaptiveCareGapOverride)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCareGapOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCareGapOverrideStore: AdaptiveCareGapOverrideStore {
        var items: [String: AdaptiveCareGapOverride]
        var order: [String]

        init(items: [String: AdaptiveCareGapOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCareGapOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCareGapOverride) {
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

        func list() -> [AdaptiveCareGapOverride] {
            var out: [AdaptiveCareGapOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCareGapOverrideStore() -> any AdaptiveCareGapOverrideStore {
        return MemoryAdaptiveCareGapOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCareGapOverrideStore: AdaptiveCareGapOverrideStore {
        var inner: MemoryAdaptiveCareGapOverrideStore
        var cache: TTLCache<AdaptiveCareGapOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCareGapOverrideStore, cache: TTLCache<AdaptiveCareGapOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCareGapOverride? {
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

        func save(_ item: AdaptiveCareGapOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCareGapOverride] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCareGapOverrideStore(_ inner: MemoryAdaptiveCareGapOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCareGapOverrideStore {
        return CachedAdaptiveCareGapOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive care gap overrides. Empty fields match all.
    final class AdaptiveCareGapOverrideQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCareGapOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCareGapOverride]) -> [AdaptiveCareGapOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCareGapOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCareGapOverrides(_ store: any AdaptiveCareGapOverrideStore, query: AdaptiveCareGapOverrideQuery) -> [AdaptiveCareGapOverride] {
        return query.apply(store.list())
    }
}
