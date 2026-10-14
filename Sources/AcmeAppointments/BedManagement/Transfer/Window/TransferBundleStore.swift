import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer bundles by code.
    protocol TransferBundleStore {
        func find(_ code: String) -> TransferBundle?
        func save(_ item: TransferBundle)
        func remove(_ code: String) -> Bool
        func list() -> [TransferBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferBundleStore: TransferBundleStore {
        var items: [String: TransferBundle]
        var order: [String]

        init(items: [String: TransferBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferBundle) {
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

        func list() -> [TransferBundle] {
            var out: [TransferBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferBundleStore() -> any TransferBundleStore {
        return MemoryTransferBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferBundleStore: TransferBundleStore {
        var inner: MemoryTransferBundleStore
        var cache: TTLCache<TransferBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferBundleStore, cache: TTLCache<TransferBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferBundle? {
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

        func save(_ item: TransferBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferBundle] {
            return inner.list()
        }
    }

    static func newCachedTransferBundleStore(_ inner: MemoryTransferBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferBundleStore {
        return CachedTransferBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer bundles. Empty fields match all.
    final class TransferBundleQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferBundle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferBundle]) -> [TransferBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferBundles(_ store: any TransferBundleStore, query: TransferBundleQuery) -> [TransferBundle] {
        return query.apply(store.list())
    }
}
