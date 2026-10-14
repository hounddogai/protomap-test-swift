import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier manifests by code.
    protocol CourierManifestStore {
        func find(_ code: String) -> CourierManifest?
        func save(_ item: CourierManifest)
        func remove(_ code: String) -> Bool
        func list() -> [CourierManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierManifestStore: CourierManifestStore {
        var items: [String: CourierManifest]
        var order: [String]

        init(items: [String: CourierManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierManifest) {
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

        func list() -> [CourierManifest] {
            var out: [CourierManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierManifestStore() -> any CourierManifestStore {
        return MemoryCourierManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierManifestStore: CourierManifestStore {
        var inner: MemoryCourierManifestStore
        var cache: TTLCache<CourierManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierManifestStore, cache: TTLCache<CourierManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierManifest? {
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

        func save(_ item: CourierManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierManifest] {
            return inner.list()
        }
    }

    static func newCachedCourierManifestStore(_ inner: MemoryCourierManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierManifestStore {
        return CachedCourierManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier manifests. Empty fields match all.
    final class CourierManifestQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierManifest]) -> [CourierManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierManifests(_ store: any CourierManifestStore, query: CourierManifestQuery) -> [CourierManifest] {
        return query.apply(store.list())
    }
}
