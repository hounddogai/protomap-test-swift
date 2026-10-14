import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach manifests by code.
    protocol OutreachManifestStore {
        func find(_ code: String) -> OutreachManifest?
        func save(_ item: OutreachManifest)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachManifestStore: OutreachManifestStore {
        var items: [String: OutreachManifest]
        var order: [String]

        init(items: [String: OutreachManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachManifest) {
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

        func list() -> [OutreachManifest] {
            var out: [OutreachManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachManifestStore() -> any OutreachManifestStore {
        return MemoryOutreachManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachManifestStore: OutreachManifestStore {
        var inner: MemoryOutreachManifestStore
        var cache: TTLCache<OutreachManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachManifestStore, cache: TTLCache<OutreachManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachManifest? {
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

        func save(_ item: OutreachManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachManifest] {
            return inner.list()
        }
    }

    static func newCachedOutreachManifestStore(_ inner: MemoryOutreachManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachManifestStore {
        return CachedOutreachManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach manifests. Empty fields match all.
    final class OutreachManifestQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachManifest]) -> [OutreachManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachManifests(_ store: any OutreachManifestStore, query: OutreachManifestQuery) -> [OutreachManifest] {
        return query.apply(store.list())
    }
}
