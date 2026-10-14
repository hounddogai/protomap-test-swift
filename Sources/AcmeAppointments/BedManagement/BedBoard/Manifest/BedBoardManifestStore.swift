import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board manifests by code.
    protocol BedBoardManifestStore {
        func find(_ code: String) -> BedBoardManifest?
        func save(_ item: BedBoardManifest)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardManifestStore: BedBoardManifestStore {
        var items: [String: BedBoardManifest]
        var order: [String]

        init(items: [String: BedBoardManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardManifest) {
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

        func list() -> [BedBoardManifest] {
            var out: [BedBoardManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardManifestStore() -> any BedBoardManifestStore {
        return MemoryBedBoardManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardManifestStore: BedBoardManifestStore {
        var inner: MemoryBedBoardManifestStore
        var cache: TTLCache<BedBoardManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardManifestStore, cache: TTLCache<BedBoardManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardManifest? {
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

        func save(_ item: BedBoardManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardManifest] {
            return inner.list()
        }
    }

    static func newCachedBedBoardManifestStore(_ inner: MemoryBedBoardManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardManifestStore {
        return CachedBedBoardManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board manifests. Empty fields match all.
    final class BedBoardManifestQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [BedBoardManifest]) -> [BedBoardManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardManifests(_ store: any BedBoardManifestStore, query: BedBoardManifestQuery) -> [BedBoardManifest] {
        return query.apply(store.list())
    }
}
