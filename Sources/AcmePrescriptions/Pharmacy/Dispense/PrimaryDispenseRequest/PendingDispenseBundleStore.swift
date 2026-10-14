import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending dispense bundles by code.
    protocol PendingDispenseBundleStore {
        func find(_ code: String) -> PendingDispenseBundle?
        func save(_ item: PendingDispenseBundle)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDispenseBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDispenseBundleStore: PendingDispenseBundleStore {
        var items: [String: PendingDispenseBundle]
        var order: [String]

        init(items: [String: PendingDispenseBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDispenseBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDispenseBundle) {
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

        func list() -> [PendingDispenseBundle] {
            var out: [PendingDispenseBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDispenseBundleStore() -> any PendingDispenseBundleStore {
        return MemoryPendingDispenseBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDispenseBundleStore: PendingDispenseBundleStore {
        var inner: MemoryPendingDispenseBundleStore
        var cache: TTLCache<PendingDispenseBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDispenseBundleStore, cache: TTLCache<PendingDispenseBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDispenseBundle? {
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

        func save(_ item: PendingDispenseBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDispenseBundle] {
            return inner.list()
        }
    }

    static func newCachedPendingDispenseBundleStore(_ inner: MemoryPendingDispenseBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDispenseBundleStore {
        return CachedPendingDispenseBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending dispense bundles. Empty fields match all.
    final class PendingDispenseBundleQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDispenseBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDispenseBundle]) -> [PendingDispenseBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDispenseBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDispenseBundles(_ store: any PendingDispenseBundleStore, query: PendingDispenseBundleQuery) -> [PendingDispenseBundle] {
        return query.apply(store.list())
    }
}
