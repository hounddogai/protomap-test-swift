import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive cleaning overrides by code.
    protocol AdaptiveCleaningOverrideStore {
        func find(_ code: String) -> AdaptiveCleaningOverride?
        func save(_ item: AdaptiveCleaningOverride)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCleaningOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCleaningOverrideStore: AdaptiveCleaningOverrideStore {
        var items: [String: AdaptiveCleaningOverride]
        var order: [String]

        init(items: [String: AdaptiveCleaningOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCleaningOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCleaningOverride) {
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

        func list() -> [AdaptiveCleaningOverride] {
            var out: [AdaptiveCleaningOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCleaningOverrideStore() -> any AdaptiveCleaningOverrideStore {
        return MemoryAdaptiveCleaningOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCleaningOverrideStore: AdaptiveCleaningOverrideStore {
        var inner: MemoryAdaptiveCleaningOverrideStore
        var cache: TTLCache<AdaptiveCleaningOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCleaningOverrideStore, cache: TTLCache<AdaptiveCleaningOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCleaningOverride? {
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

        func save(_ item: AdaptiveCleaningOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCleaningOverride] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCleaningOverrideStore(_ inner: MemoryAdaptiveCleaningOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCleaningOverrideStore {
        return CachedAdaptiveCleaningOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive cleaning overrides. Empty fields match all.
    final class AdaptiveCleaningOverrideQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCleaningOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [AdaptiveCleaningOverride]) -> [AdaptiveCleaningOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCleaningOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCleaningOverrides(_ store: any AdaptiveCleaningOverrideStore, query: AdaptiveCleaningOverrideQuery) -> [AdaptiveCleaningOverride] {
        return query.apply(store.list())
    }
}
