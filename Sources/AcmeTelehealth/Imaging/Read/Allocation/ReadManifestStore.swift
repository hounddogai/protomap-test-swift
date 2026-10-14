import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read manifests by code.
    protocol ReadManifestStore {
        func find(_ code: String) -> ReadManifest?
        func save(_ item: ReadManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ReadManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadManifestStore: ReadManifestStore {
        var items: [String: ReadManifest]
        var order: [String]

        init(items: [String: ReadManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadManifest) {
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

        func list() -> [ReadManifest] {
            var out: [ReadManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadManifestStore() -> any ReadManifestStore {
        return MemoryReadManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadManifestStore: ReadManifestStore {
        var inner: MemoryReadManifestStore
        var cache: TTLCache<ReadManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadManifestStore, cache: TTLCache<ReadManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadManifest? {
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

        func save(_ item: ReadManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadManifest] {
            return inner.list()
        }
    }

    static func newCachedReadManifestStore(_ inner: MemoryReadManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadManifestStore {
        return CachedReadManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read manifests. Empty fields match all.
    final class ReadManifestQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadManifest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadManifest]) -> [ReadManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadManifests(_ store: any ReadManifestStore, query: ReadManifestQuery) -> [ReadManifest] {
        return query.apply(store.list())
    }
}
