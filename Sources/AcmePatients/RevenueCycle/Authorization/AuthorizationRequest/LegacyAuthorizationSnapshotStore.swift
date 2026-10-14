import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy authorization snapshots by code.
    protocol LegacyAuthorizationSnapshotStore {
        func find(_ code: String) -> LegacyAuthorizationSnapshot?
        func save(_ item: LegacyAuthorizationSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAuthorizationSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAuthorizationSnapshotStore: LegacyAuthorizationSnapshotStore {
        var items: [String: LegacyAuthorizationSnapshot]
        var order: [String]

        init(items: [String: LegacyAuthorizationSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAuthorizationSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAuthorizationSnapshot) {
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

        func list() -> [LegacyAuthorizationSnapshot] {
            var out: [LegacyAuthorizationSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAuthorizationSnapshotStore() -> any LegacyAuthorizationSnapshotStore {
        return MemoryLegacyAuthorizationSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAuthorizationSnapshotStore: LegacyAuthorizationSnapshotStore {
        var inner: MemoryLegacyAuthorizationSnapshotStore
        var cache: TTLCache<LegacyAuthorizationSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAuthorizationSnapshotStore, cache: TTLCache<LegacyAuthorizationSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAuthorizationSnapshot? {
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

        func save(_ item: LegacyAuthorizationSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAuthorizationSnapshot] {
            return inner.list()
        }
    }

    static func newCachedLegacyAuthorizationSnapshotStore(_ inner: MemoryLegacyAuthorizationSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAuthorizationSnapshotStore {
        return CachedLegacyAuthorizationSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy authorization snapshots. Empty fields match all.
    final class LegacyAuthorizationSnapshotQuery {
        var locale: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAuthorizationSnapshot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAuthorizationSnapshot]) -> [LegacyAuthorizationSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAuthorizationSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAuthorizationSnapshots(_ store: any LegacyAuthorizationSnapshotStore, query: LegacyAuthorizationSnapshotQuery) -> [LegacyAuthorizationSnapshot] {
        return query.apply(store.list())
    }
}
