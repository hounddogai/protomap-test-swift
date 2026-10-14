import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient consent form snapshots by code.
    protocol LenientConsentFormSnapshotStore {
        func find(_ code: String) -> LenientConsentFormSnapshot?
        func save(_ item: LenientConsentFormSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LenientConsentFormSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientConsentFormSnapshotStore: LenientConsentFormSnapshotStore {
        var items: [String: LenientConsentFormSnapshot]
        var order: [String]

        init(items: [String: LenientConsentFormSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientConsentFormSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientConsentFormSnapshot) {
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

        func list() -> [LenientConsentFormSnapshot] {
            var out: [LenientConsentFormSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientConsentFormSnapshotStore() -> any LenientConsentFormSnapshotStore {
        return MemoryLenientConsentFormSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientConsentFormSnapshotStore: LenientConsentFormSnapshotStore {
        var inner: MemoryLenientConsentFormSnapshotStore
        var cache: TTLCache<LenientConsentFormSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientConsentFormSnapshotStore, cache: TTLCache<LenientConsentFormSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientConsentFormSnapshot? {
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

        func save(_ item: LenientConsentFormSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientConsentFormSnapshot] {
            return inner.list()
        }
    }

    static func newCachedLenientConsentFormSnapshotStore(_ inner: MemoryLenientConsentFormSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientConsentFormSnapshotStore {
        return CachedLenientConsentFormSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient consent form snapshots. Empty fields match all.
    final class LenientConsentFormSnapshotQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientConsentFormSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LenientConsentFormSnapshot]) -> [LenientConsentFormSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientConsentFormSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientConsentFormSnapshots(_ store: any LenientConsentFormSnapshotStore, query: LenientConsentFormSnapshotQuery) -> [LenientConsentFormSnapshot] {
        return query.apply(store.list())
    }
}
