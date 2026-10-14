import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach overrides by code.
    protocol OutreachOverrideStore {
        func find(_ code: String) -> OutreachOverride?
        func save(_ item: OutreachOverride)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachOverrideStore: OutreachOverrideStore {
        var items: [String: OutreachOverride]
        var order: [String]

        init(items: [String: OutreachOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachOverride) {
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

        func list() -> [OutreachOverride] {
            var out: [OutreachOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachOverrideStore() -> any OutreachOverrideStore {
        return MemoryOutreachOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachOverrideStore: OutreachOverrideStore {
        var inner: MemoryOutreachOverrideStore
        var cache: TTLCache<OutreachOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachOverrideStore, cache: TTLCache<OutreachOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachOverride? {
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

        func save(_ item: OutreachOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachOverride] {
            return inner.list()
        }
    }

    static func newCachedOutreachOverrideStore(_ inner: MemoryOutreachOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachOverrideStore {
        return CachedOutreachOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach overrides. Empty fields match all.
    final class OutreachOverrideQuery {
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

        func matches(_ item: OutreachOverride) -> Bool {
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

        func apply(_ items: [OutreachOverride]) -> [OutreachOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachOverrides(_ store: any OutreachOverrideStore, query: OutreachOverrideQuery) -> [OutreachOverride] {
        return query.apply(store.list())
    }
}
