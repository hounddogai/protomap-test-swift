import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure digests by code.
    protocol DisclosureDigestStore {
        func find(_ code: String) -> DisclosureDigest?
        func save(_ item: DisclosureDigest)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureDigestStore: DisclosureDigestStore {
        var items: [String: DisclosureDigest]
        var order: [String]

        init(items: [String: DisclosureDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureDigest) {
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

        func list() -> [DisclosureDigest] {
            var out: [DisclosureDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureDigestStore() -> any DisclosureDigestStore {
        return MemoryDisclosureDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureDigestStore: DisclosureDigestStore {
        var inner: MemoryDisclosureDigestStore
        var cache: TTLCache<DisclosureDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureDigestStore, cache: TTLCache<DisclosureDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureDigest? {
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

        func save(_ item: DisclosureDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureDigest] {
            return inner.list()
        }
    }

    static func newCachedDisclosureDigestStore(_ inner: MemoryDisclosureDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureDigestStore {
        return CachedDisclosureDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure digests. Empty fields match all.
    final class DisclosureDigestQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DisclosureDigest]) -> [DisclosureDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureDigests(_ store: any DisclosureDigestStore, query: DisclosureDigestQuery) -> [DisclosureDigest] {
        return query.apply(store.list())
    }
}
