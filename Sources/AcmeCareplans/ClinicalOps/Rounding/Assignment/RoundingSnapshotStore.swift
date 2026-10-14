import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding snapshots by code.
    protocol RoundingSnapshotStore {
        func find(_ code: String) -> RoundingSnapshot?
        func save(_ item: RoundingSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingSnapshotStore: RoundingSnapshotStore {
        var items: [String: RoundingSnapshot]
        var order: [String]

        init(items: [String: RoundingSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingSnapshot) {
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

        func list() -> [RoundingSnapshot] {
            var out: [RoundingSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingSnapshotStore() -> any RoundingSnapshotStore {
        return MemoryRoundingSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingSnapshotStore: RoundingSnapshotStore {
        var inner: MemoryRoundingSnapshotStore
        var cache: TTLCache<RoundingSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingSnapshotStore, cache: TTLCache<RoundingSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingSnapshot? {
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

        func save(_ item: RoundingSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingSnapshot] {
            return inner.list()
        }
    }

    static func newCachedRoundingSnapshotStore(_ inner: MemoryRoundingSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingSnapshotStore {
        return CachedRoundingSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding snapshots. Empty fields match all.
    final class RoundingSnapshotQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingSnapshot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingSnapshot]) -> [RoundingSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingSnapshots(_ store: any RoundingSnapshotStore, query: RoundingSnapshotQuery) -> [RoundingSnapshot] {
        return query.apply(store.list())
    }
}
