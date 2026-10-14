import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range manifests by code.
    protocol ReferenceRangeManifestStore {
        func find(_ code: String) -> ReferenceRangeManifest?
        func save(_ item: ReferenceRangeManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeManifestStore: ReferenceRangeManifestStore {
        var items: [String: ReferenceRangeManifest]
        var order: [String]

        init(items: [String: ReferenceRangeManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeManifest) {
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

        func list() -> [ReferenceRangeManifest] {
            var out: [ReferenceRangeManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeManifestStore() -> any ReferenceRangeManifestStore {
        return MemoryReferenceRangeManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeManifestStore: ReferenceRangeManifestStore {
        var inner: MemoryReferenceRangeManifestStore
        var cache: TTLCache<ReferenceRangeManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeManifestStore, cache: TTLCache<ReferenceRangeManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeManifest? {
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

        func save(_ item: ReferenceRangeManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeManifest] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeManifestStore(_ inner: MemoryReferenceRangeManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeManifestStore {
        return CachedReferenceRangeManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range manifests. Empty fields match all.
    final class ReferenceRangeManifestQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeManifest]) -> [ReferenceRangeManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeManifests(_ store: any ReferenceRangeManifestStore, query: ReferenceRangeManifestQuery) -> [ReferenceRangeManifest] {
        return query.apply(store.list())
    }
}
