import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel digests by code.
    protocol PanelDigestStore {
        func find(_ code: String) -> PanelDigest?
        func save(_ item: PanelDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PanelDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelDigestStore: PanelDigestStore {
        var items: [String: PanelDigest]
        var order: [String]

        init(items: [String: PanelDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelDigest) {
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

        func list() -> [PanelDigest] {
            var out: [PanelDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelDigestStore() -> any PanelDigestStore {
        return MemoryPanelDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelDigestStore: PanelDigestStore {
        var inner: MemoryPanelDigestStore
        var cache: TTLCache<PanelDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelDigestStore, cache: TTLCache<PanelDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelDigest? {
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

        func save(_ item: PanelDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelDigest] {
            return inner.list()
        }
    }

    static func newCachedPanelDigestStore(_ inner: MemoryPanelDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelDigestStore {
        return CachedPanelDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel digests. Empty fields match all.
    final class PanelDigestQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelDigest]) -> [PanelDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelDigests(_ store: any PanelDigestStore, query: PanelDigestQuery) -> [PanelDigest] {
        return query.apply(store.list())
    }
}
