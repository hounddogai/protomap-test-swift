import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global care gap overrides by code.
    protocol GlobalCareGapOverrideStore {
        func find(_ code: String) -> GlobalCareGapOverride?
        func save(_ item: GlobalCareGapOverride)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareGapOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareGapOverrideStore: GlobalCareGapOverrideStore {
        var items: [String: GlobalCareGapOverride]
        var order: [String]

        init(items: [String: GlobalCareGapOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareGapOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareGapOverride) {
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

        func list() -> [GlobalCareGapOverride] {
            var out: [GlobalCareGapOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareGapOverrideStore() -> any GlobalCareGapOverrideStore {
        return MemoryGlobalCareGapOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareGapOverrideStore: GlobalCareGapOverrideStore {
        var inner: MemoryGlobalCareGapOverrideStore
        var cache: TTLCache<GlobalCareGapOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareGapOverrideStore, cache: TTLCache<GlobalCareGapOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareGapOverride? {
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

        func save(_ item: GlobalCareGapOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareGapOverride] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareGapOverrideStore(_ inner: MemoryGlobalCareGapOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareGapOverrideStore {
        return CachedGlobalCareGapOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care gap overrides. Empty fields match all.
    final class GlobalCareGapOverrideQuery {
        var locale: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minLimit: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCareGapOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCareGapOverride]) -> [GlobalCareGapOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareGapOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareGapOverrides(_ store: any GlobalCareGapOverrideStore, query: GlobalCareGapOverrideQuery) -> [GlobalCareGapOverride] {
        return query.apply(store.list())
    }
}
