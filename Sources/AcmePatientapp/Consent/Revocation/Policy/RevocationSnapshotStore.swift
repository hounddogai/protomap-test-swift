import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation snapshots by code.
    protocol RevocationSnapshotStore {
        func find(_ code: String) -> RevocationSnapshot?
        func save(_ item: RevocationSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationSnapshotStore: RevocationSnapshotStore {
        var items: [String: RevocationSnapshot]
        var order: [String]

        init(items: [String: RevocationSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationSnapshot) {
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

        func list() -> [RevocationSnapshot] {
            var out: [RevocationSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationSnapshotStore() -> any RevocationSnapshotStore {
        return MemoryRevocationSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationSnapshotStore: RevocationSnapshotStore {
        var inner: MemoryRevocationSnapshotStore
        var cache: TTLCache<RevocationSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationSnapshotStore, cache: TTLCache<RevocationSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationSnapshot? {
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

        func save(_ item: RevocationSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationSnapshot] {
            return inner.list()
        }
    }

    static func newCachedRevocationSnapshotStore(_ inner: MemoryRevocationSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationSnapshotStore {
        return CachedRevocationSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation snapshots. Empty fields match all.
    final class RevocationSnapshotQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationSnapshot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationSnapshot]) -> [RevocationSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationSnapshots(_ store: any RevocationSnapshotStore, query: RevocationSnapshotQuery) -> [RevocationSnapshot] {
        return query.apply(store.list())
    }
}
