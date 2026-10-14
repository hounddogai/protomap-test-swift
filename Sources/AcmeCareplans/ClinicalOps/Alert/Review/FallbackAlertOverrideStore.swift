import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback alert overrides by code.
    protocol FallbackAlertOverrideStore {
        func find(_ code: String) -> FallbackAlertOverride?
        func save(_ item: FallbackAlertOverride)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAlertOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAlertOverrideStore: FallbackAlertOverrideStore {
        var items: [String: FallbackAlertOverride]
        var order: [String]

        init(items: [String: FallbackAlertOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAlertOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAlertOverride) {
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

        func list() -> [FallbackAlertOverride] {
            var out: [FallbackAlertOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAlertOverrideStore() -> any FallbackAlertOverrideStore {
        return MemoryFallbackAlertOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAlertOverrideStore: FallbackAlertOverrideStore {
        var inner: MemoryFallbackAlertOverrideStore
        var cache: TTLCache<FallbackAlertOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAlertOverrideStore, cache: TTLCache<FallbackAlertOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAlertOverride? {
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

        func save(_ item: FallbackAlertOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAlertOverride] {
            return inner.list()
        }
    }

    static func newCachedFallbackAlertOverrideStore(_ inner: MemoryFallbackAlertOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAlertOverrideStore {
        return CachedFallbackAlertOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback alert overrides. Empty fields match all.
    final class FallbackAlertOverrideQuery {
        var category: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRefills: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAlertOverride) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackAlertOverride]) -> [FallbackAlertOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAlertOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAlertOverrides(_ store: any FallbackAlertOverrideStore, query: FallbackAlertOverrideQuery) -> [FallbackAlertOverride] {
        return query.apply(store.list())
    }
}
