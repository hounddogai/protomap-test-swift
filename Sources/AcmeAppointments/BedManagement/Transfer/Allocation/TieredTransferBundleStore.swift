import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered transfer bundles by code.
    protocol TieredTransferBundleStore {
        func find(_ code: String) -> TieredTransferBundle?
        func save(_ item: TieredTransferBundle)
        func remove(_ code: String) -> Bool
        func list() -> [TieredTransferBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredTransferBundleStore: TieredTransferBundleStore {
        var items: [String: TieredTransferBundle]
        var order: [String]

        init(items: [String: TieredTransferBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredTransferBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredTransferBundle) {
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

        func list() -> [TieredTransferBundle] {
            var out: [TieredTransferBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredTransferBundleStore() -> any TieredTransferBundleStore {
        return MemoryTieredTransferBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredTransferBundleStore: TieredTransferBundleStore {
        var inner: MemoryTieredTransferBundleStore
        var cache: TTLCache<TieredTransferBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredTransferBundleStore, cache: TTLCache<TieredTransferBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredTransferBundle? {
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

        func save(_ item: TieredTransferBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredTransferBundle] {
            return inner.list()
        }
    }

    static func newCachedTieredTransferBundleStore(_ inner: MemoryTieredTransferBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredTransferBundleStore {
        return CachedTieredTransferBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered transfer bundles. Empty fields match all.
    final class TieredTransferBundleQuery {
        var locale: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minSequence: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredTransferBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredTransferBundle]) -> [TieredTransferBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredTransferBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredTransferBundles(_ store: any TieredTransferBundleStore, query: TieredTransferBundleQuery) -> [TieredTransferBundle] {
        return query.apply(store.list())
    }
}
