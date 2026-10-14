import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback handoff thresholds by code.
    protocol FallbackHandoffThresholdStore {
        func find(_ code: String) -> FallbackHandoffThreshold?
        func save(_ item: FallbackHandoffThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackHandoffThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackHandoffThresholdStore: FallbackHandoffThresholdStore {
        var items: [String: FallbackHandoffThreshold]
        var order: [String]

        init(items: [String: FallbackHandoffThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackHandoffThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackHandoffThreshold) {
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

        func list() -> [FallbackHandoffThreshold] {
            var out: [FallbackHandoffThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackHandoffThresholdStore() -> any FallbackHandoffThresholdStore {
        return MemoryFallbackHandoffThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackHandoffThresholdStore: FallbackHandoffThresholdStore {
        var inner: MemoryFallbackHandoffThresholdStore
        var cache: TTLCache<FallbackHandoffThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackHandoffThresholdStore, cache: TTLCache<FallbackHandoffThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackHandoffThreshold? {
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

        func save(_ item: FallbackHandoffThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackHandoffThreshold] {
            return inner.list()
        }
    }

    static func newCachedFallbackHandoffThresholdStore(_ inner: MemoryFallbackHandoffThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackHandoffThresholdStore {
        return CachedFallbackHandoffThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback handoff thresholds. Empty fields match all.
    final class FallbackHandoffThresholdQuery {
        var locale: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackHandoffThreshold) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [FallbackHandoffThreshold]) -> [FallbackHandoffThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackHandoffThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackHandoffThresholds(_ store: any FallbackHandoffThresholdStore, query: FallbackHandoffThresholdQuery) -> [FallbackHandoffThreshold] {
        return query.apply(store.list())
    }
}
