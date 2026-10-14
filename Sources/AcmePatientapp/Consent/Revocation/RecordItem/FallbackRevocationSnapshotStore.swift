import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback revocation snapshots by code.
    protocol FallbackRevocationSnapshotStore {
        func find(_ code: String) -> FallbackRevocationSnapshot?
        func save(_ item: FallbackRevocationSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRevocationSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRevocationSnapshotStore: FallbackRevocationSnapshotStore {
        var items: [String: FallbackRevocationSnapshot]
        var order: [String]

        init(items: [String: FallbackRevocationSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRevocationSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRevocationSnapshot) {
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

        func list() -> [FallbackRevocationSnapshot] {
            var out: [FallbackRevocationSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRevocationSnapshotStore() -> any FallbackRevocationSnapshotStore {
        return MemoryFallbackRevocationSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRevocationSnapshotStore: FallbackRevocationSnapshotStore {
        var inner: MemoryFallbackRevocationSnapshotStore
        var cache: TTLCache<FallbackRevocationSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRevocationSnapshotStore, cache: TTLCache<FallbackRevocationSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRevocationSnapshot? {
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

        func save(_ item: FallbackRevocationSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRevocationSnapshot] {
            return inner.list()
        }
    }

    static func newCachedFallbackRevocationSnapshotStore(_ inner: MemoryFallbackRevocationSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRevocationSnapshotStore {
        return CachedFallbackRevocationSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback revocation snapshots. Empty fields match all.
    final class FallbackRevocationSnapshotQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRevocationSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRevocationSnapshot]) -> [FallbackRevocationSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRevocationSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRevocationSnapshots(_ store: any FallbackRevocationSnapshotStore, query: FallbackRevocationSnapshotQuery) -> [FallbackRevocationSnapshot] {
        return query.apply(store.list())
    }
}
