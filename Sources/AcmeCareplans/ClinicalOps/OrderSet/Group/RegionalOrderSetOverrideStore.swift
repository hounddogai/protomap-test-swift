import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional order set overrides by code.
    protocol RegionalOrderSetOverrideStore {
        func find(_ code: String) -> RegionalOrderSetOverride?
        func save(_ item: RegionalOrderSetOverride)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalOrderSetOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalOrderSetOverrideStore: RegionalOrderSetOverrideStore {
        var items: [String: RegionalOrderSetOverride]
        var order: [String]

        init(items: [String: RegionalOrderSetOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalOrderSetOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalOrderSetOverride) {
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

        func list() -> [RegionalOrderSetOverride] {
            var out: [RegionalOrderSetOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalOrderSetOverrideStore() -> any RegionalOrderSetOverrideStore {
        return MemoryRegionalOrderSetOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalOrderSetOverrideStore: RegionalOrderSetOverrideStore {
        var inner: MemoryRegionalOrderSetOverrideStore
        var cache: TTLCache<RegionalOrderSetOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalOrderSetOverrideStore, cache: TTLCache<RegionalOrderSetOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalOrderSetOverride? {
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

        func save(_ item: RegionalOrderSetOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalOrderSetOverride] {
            return inner.list()
        }
    }

    static func newCachedRegionalOrderSetOverrideStore(_ inner: MemoryRegionalOrderSetOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalOrderSetOverrideStore {
        return CachedRegionalOrderSetOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional order set overrides. Empty fields match all.
    final class RegionalOrderSetOverrideQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalOrderSetOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalOrderSetOverride]) -> [RegionalOrderSetOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalOrderSetOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalOrderSetOverrides(_ store: any RegionalOrderSetOverrideStore, query: RegionalOrderSetOverrideQuery) -> [RegionalOrderSetOverride] {
        return query.apply(store.list())
    }
}
