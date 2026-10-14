import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol overrides by code.
    protocol CareProtocolOverrideStore {
        func find(_ code: String) -> CareProtocolOverride?
        func save(_ item: CareProtocolOverride)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolOverrideStore: CareProtocolOverrideStore {
        var items: [String: CareProtocolOverride]
        var order: [String]

        init(items: [String: CareProtocolOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolOverride) {
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

        func list() -> [CareProtocolOverride] {
            var out: [CareProtocolOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolOverrideStore() -> any CareProtocolOverrideStore {
        return MemoryCareProtocolOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolOverrideStore: CareProtocolOverrideStore {
        var inner: MemoryCareProtocolOverrideStore
        var cache: TTLCache<CareProtocolOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolOverrideStore, cache: TTLCache<CareProtocolOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolOverride? {
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

        func save(_ item: CareProtocolOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolOverride] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolOverrideStore(_ inner: MemoryCareProtocolOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolOverrideStore {
        return CachedCareProtocolOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol overrides. Empty fields match all.
    final class CareProtocolOverrideQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolOverride]) -> [CareProtocolOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolOverrides(_ store: any CareProtocolOverrideStore, query: CareProtocolOverrideQuery) -> [CareProtocolOverride] {
        return query.apply(store.list())
    }
}
