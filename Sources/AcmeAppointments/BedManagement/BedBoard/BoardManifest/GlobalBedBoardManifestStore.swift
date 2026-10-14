import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global bed board manifests by code.
    protocol GlobalBedBoardManifestStore {
        func find(_ code: String) -> GlobalBedBoardManifest?
        func save(_ item: GlobalBedBoardManifest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalBedBoardManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalBedBoardManifestStore: GlobalBedBoardManifestStore {
        var items: [String: GlobalBedBoardManifest]
        var order: [String]

        init(items: [String: GlobalBedBoardManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalBedBoardManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalBedBoardManifest) {
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

        func list() -> [GlobalBedBoardManifest] {
            var out: [GlobalBedBoardManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalBedBoardManifestStore() -> any GlobalBedBoardManifestStore {
        return MemoryGlobalBedBoardManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalBedBoardManifestStore: GlobalBedBoardManifestStore {
        var inner: MemoryGlobalBedBoardManifestStore
        var cache: TTLCache<GlobalBedBoardManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalBedBoardManifestStore, cache: TTLCache<GlobalBedBoardManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalBedBoardManifest? {
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

        func save(_ item: GlobalBedBoardManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalBedBoardManifest] {
            return inner.list()
        }
    }

    static func newCachedGlobalBedBoardManifestStore(_ inner: MemoryGlobalBedBoardManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalBedBoardManifestStore {
        return CachedGlobalBedBoardManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global bed board manifests. Empty fields match all.
    final class GlobalBedBoardManifestQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalBedBoardManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalBedBoardManifest]) -> [GlobalBedBoardManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalBedBoardManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalBedBoardManifests(_ store: any GlobalBedBoardManifestStore, query: GlobalBedBoardManifestQuery) -> [GlobalBedBoardManifest] {
        return query.apply(store.list())
    }
}
