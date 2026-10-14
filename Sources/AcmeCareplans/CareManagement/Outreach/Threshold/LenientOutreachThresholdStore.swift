import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient outreach thresholds by code.
    protocol LenientOutreachThresholdStore {
        func find(_ code: String) -> LenientOutreachThreshold?
        func save(_ item: LenientOutreachThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOutreachThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOutreachThresholdStore: LenientOutreachThresholdStore {
        var items: [String: LenientOutreachThreshold]
        var order: [String]

        init(items: [String: LenientOutreachThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOutreachThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOutreachThreshold) {
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

        func list() -> [LenientOutreachThreshold] {
            var out: [LenientOutreachThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOutreachThresholdStore() -> any LenientOutreachThresholdStore {
        return MemoryLenientOutreachThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOutreachThresholdStore: LenientOutreachThresholdStore {
        var inner: MemoryLenientOutreachThresholdStore
        var cache: TTLCache<LenientOutreachThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOutreachThresholdStore, cache: TTLCache<LenientOutreachThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOutreachThreshold? {
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

        func save(_ item: LenientOutreachThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOutreachThreshold] {
            return inner.list()
        }
    }

    static func newCachedLenientOutreachThresholdStore(_ inner: MemoryLenientOutreachThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOutreachThresholdStore {
        return CachedLenientOutreachThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient outreach thresholds. Empty fields match all.
    final class LenientOutreachThresholdQuery {
        var unit: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOutreachThreshold) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientOutreachThreshold]) -> [LenientOutreachThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOutreachThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOutreachThresholds(_ store: any LenientOutreachThresholdStore, query: LenientOutreachThresholdQuery) -> [LenientOutreachThreshold] {
        return query.apply(store.list())
    }
}
