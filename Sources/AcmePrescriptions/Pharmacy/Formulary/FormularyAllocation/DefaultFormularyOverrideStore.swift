import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default formulary overrides by code.
    protocol DefaultFormularyOverrideStore {
        func find(_ code: String) -> DefaultFormularyOverride?
        func save(_ item: DefaultFormularyOverride)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultFormularyOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultFormularyOverrideStore: DefaultFormularyOverrideStore {
        var items: [String: DefaultFormularyOverride]
        var order: [String]

        init(items: [String: DefaultFormularyOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultFormularyOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultFormularyOverride) {
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

        func list() -> [DefaultFormularyOverride] {
            var out: [DefaultFormularyOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultFormularyOverrideStore() -> any DefaultFormularyOverrideStore {
        return MemoryDefaultFormularyOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultFormularyOverrideStore: DefaultFormularyOverrideStore {
        var inner: MemoryDefaultFormularyOverrideStore
        var cache: TTLCache<DefaultFormularyOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultFormularyOverrideStore, cache: TTLCache<DefaultFormularyOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultFormularyOverride? {
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

        func save(_ item: DefaultFormularyOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultFormularyOverride] {
            return inner.list()
        }
    }

    static func newCachedDefaultFormularyOverrideStore(_ inner: MemoryDefaultFormularyOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultFormularyOverrideStore {
        return CachedDefaultFormularyOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default formulary overrides. Empty fields match all.
    final class DefaultFormularyOverrideQuery {
        var ward: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minLimit: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultFormularyOverride) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [DefaultFormularyOverride]) -> [DefaultFormularyOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultFormularyOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultFormularyOverrides(_ store: any DefaultFormularyOverrideStore, query: DefaultFormularyOverrideQuery) -> [DefaultFormularyOverride] {
        return query.apply(store.list())
    }
}
