import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global disclosure baselines by code.
    protocol GlobalDisclosureBaselineStore {
        func find(_ code: String) -> GlobalDisclosureBaseline?
        func save(_ item: GlobalDisclosureBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDisclosureBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDisclosureBaselineStore: GlobalDisclosureBaselineStore {
        var items: [String: GlobalDisclosureBaseline]
        var order: [String]

        init(items: [String: GlobalDisclosureBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDisclosureBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDisclosureBaseline) {
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

        func list() -> [GlobalDisclosureBaseline] {
            var out: [GlobalDisclosureBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDisclosureBaselineStore() -> any GlobalDisclosureBaselineStore {
        return MemoryGlobalDisclosureBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDisclosureBaselineStore: GlobalDisclosureBaselineStore {
        var inner: MemoryGlobalDisclosureBaselineStore
        var cache: TTLCache<GlobalDisclosureBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDisclosureBaselineStore, cache: TTLCache<GlobalDisclosureBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDisclosureBaseline? {
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

        func save(_ item: GlobalDisclosureBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDisclosureBaseline] {
            return inner.list()
        }
    }

    static func newCachedGlobalDisclosureBaselineStore(_ inner: MemoryGlobalDisclosureBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDisclosureBaselineStore {
        return CachedGlobalDisclosureBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global disclosure baselines. Empty fields match all.
    final class GlobalDisclosureBaselineQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDisclosureBaseline) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalDisclosureBaseline]) -> [GlobalDisclosureBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDisclosureBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDisclosureBaselines(_ store: any GlobalDisclosureBaselineStore, query: GlobalDisclosureBaselineQuery) -> [GlobalDisclosureBaseline] {
        return query.apply(store.list())
    }
}
