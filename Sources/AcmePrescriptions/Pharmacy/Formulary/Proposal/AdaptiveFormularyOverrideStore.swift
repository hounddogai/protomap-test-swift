import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive formulary overrides by code.
    protocol AdaptiveFormularyOverrideStore {
        func find(_ code: String) -> AdaptiveFormularyOverride?
        func save(_ item: AdaptiveFormularyOverride)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFormularyOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFormularyOverrideStore: AdaptiveFormularyOverrideStore {
        var items: [String: AdaptiveFormularyOverride]
        var order: [String]

        init(items: [String: AdaptiveFormularyOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFormularyOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFormularyOverride) {
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

        func list() -> [AdaptiveFormularyOverride] {
            var out: [AdaptiveFormularyOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFormularyOverrideStore() -> any AdaptiveFormularyOverrideStore {
        return MemoryAdaptiveFormularyOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFormularyOverrideStore: AdaptiveFormularyOverrideStore {
        var inner: MemoryAdaptiveFormularyOverrideStore
        var cache: TTLCache<AdaptiveFormularyOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFormularyOverrideStore, cache: TTLCache<AdaptiveFormularyOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFormularyOverride? {
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

        func save(_ item: AdaptiveFormularyOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFormularyOverride] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFormularyOverrideStore(_ inner: MemoryAdaptiveFormularyOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFormularyOverrideStore {
        return CachedAdaptiveFormularyOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive formulary overrides. Empty fields match all.
    final class AdaptiveFormularyOverrideQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveFormularyOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveFormularyOverride]) -> [AdaptiveFormularyOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFormularyOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFormularyOverrides(_ store: any AdaptiveFormularyOverrideStore, query: AdaptiveFormularyOverrideQuery) -> [AdaptiveFormularyOverride] {
        return query.apply(store.list())
    }
}
