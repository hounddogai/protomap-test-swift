import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional slot digests by code.
    protocol RegionalSlotDigestStore {
        func find(_ code: String) -> RegionalSlotDigest?
        func save(_ item: RegionalSlotDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSlotDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSlotDigestStore: RegionalSlotDigestStore {
        var items: [String: RegionalSlotDigest]
        var order: [String]

        init(items: [String: RegionalSlotDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSlotDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSlotDigest) {
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

        func list() -> [RegionalSlotDigest] {
            var out: [RegionalSlotDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSlotDigestStore() -> any RegionalSlotDigestStore {
        return MemoryRegionalSlotDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSlotDigestStore: RegionalSlotDigestStore {
        var inner: MemoryRegionalSlotDigestStore
        var cache: TTLCache<RegionalSlotDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSlotDigestStore, cache: TTLCache<RegionalSlotDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSlotDigest? {
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

        func save(_ item: RegionalSlotDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSlotDigest] {
            return inner.list()
        }
    }

    static func newCachedRegionalSlotDigestStore(_ inner: MemoryRegionalSlotDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSlotDigestStore {
        return CachedRegionalSlotDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional slot digests. Empty fields match all.
    final class RegionalSlotDigestQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSlotDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSlotDigest]) -> [RegionalSlotDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSlotDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSlotDigests(_ store: any RegionalSlotDigestStore, query: RegionalSlotDigestQuery) -> [RegionalSlotDigest] {
        return query.apply(store.list())
    }
}
