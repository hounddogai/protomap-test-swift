import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional disclosure targets by code.
    protocol RegionalDisclosureTargetStore {
        func find(_ code: String) -> RegionalDisclosureTarget?
        func save(_ item: RegionalDisclosureTarget)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDisclosureTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDisclosureTargetStore: RegionalDisclosureTargetStore {
        var items: [String: RegionalDisclosureTarget]
        var order: [String]

        init(items: [String: RegionalDisclosureTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDisclosureTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDisclosureTarget) {
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

        func list() -> [RegionalDisclosureTarget] {
            var out: [RegionalDisclosureTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDisclosureTargetStore() -> any RegionalDisclosureTargetStore {
        return MemoryRegionalDisclosureTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDisclosureTargetStore: RegionalDisclosureTargetStore {
        var inner: MemoryRegionalDisclosureTargetStore
        var cache: TTLCache<RegionalDisclosureTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDisclosureTargetStore, cache: TTLCache<RegionalDisclosureTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDisclosureTarget? {
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

        func save(_ item: RegionalDisclosureTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDisclosureTarget] {
            return inner.list()
        }
    }

    static func newCachedRegionalDisclosureTargetStore(_ inner: MemoryRegionalDisclosureTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDisclosureTargetStore {
        return CachedRegionalDisclosureTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional disclosure targets. Empty fields match all.
    final class RegionalDisclosureTargetQuery {
        var source: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDisclosureTarget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalDisclosureTarget]) -> [RegionalDisclosureTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDisclosureTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDisclosureTargets(_ store: any RegionalDisclosureTargetStore, query: RegionalDisclosureTargetQuery) -> [RegionalDisclosureTarget] {
        return query.apply(store.list())
    }
}
