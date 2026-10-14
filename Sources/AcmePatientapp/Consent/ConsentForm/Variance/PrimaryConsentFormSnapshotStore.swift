import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary consent form snapshots by code.
    protocol PrimaryConsentFormSnapshotStore {
        func find(_ code: String) -> PrimaryConsentFormSnapshot?
        func save(_ item: PrimaryConsentFormSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryConsentFormSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryConsentFormSnapshotStore: PrimaryConsentFormSnapshotStore {
        var items: [String: PrimaryConsentFormSnapshot]
        var order: [String]

        init(items: [String: PrimaryConsentFormSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryConsentFormSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryConsentFormSnapshot) {
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

        func list() -> [PrimaryConsentFormSnapshot] {
            var out: [PrimaryConsentFormSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryConsentFormSnapshotStore() -> any PrimaryConsentFormSnapshotStore {
        return MemoryPrimaryConsentFormSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryConsentFormSnapshotStore: PrimaryConsentFormSnapshotStore {
        var inner: MemoryPrimaryConsentFormSnapshotStore
        var cache: TTLCache<PrimaryConsentFormSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryConsentFormSnapshotStore, cache: TTLCache<PrimaryConsentFormSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryConsentFormSnapshot? {
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

        func save(_ item: PrimaryConsentFormSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryConsentFormSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPrimaryConsentFormSnapshotStore(_ inner: MemoryPrimaryConsentFormSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryConsentFormSnapshotStore {
        return CachedPrimaryConsentFormSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary consent form snapshots. Empty fields match all.
    final class PrimaryConsentFormSnapshotQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryConsentFormSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryConsentFormSnapshot]) -> [PrimaryConsentFormSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryConsentFormSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryConsentFormSnapshots(_ store: any PrimaryConsentFormSnapshotStore, query: PrimaryConsentFormSnapshotQuery) -> [PrimaryConsentFormSnapshot] {
        return query.apply(store.list())
    }
}
