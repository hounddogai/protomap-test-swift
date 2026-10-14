import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift manifests by code.
    protocol ShiftManifestStore {
        func find(_ code: String) -> ShiftManifest?
        func save(_ item: ShiftManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftManifestStore: ShiftManifestStore {
        var items: [String: ShiftManifest]
        var order: [String]

        init(items: [String: ShiftManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftManifest) {
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

        func list() -> [ShiftManifest] {
            var out: [ShiftManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftManifestStore() -> any ShiftManifestStore {
        return MemoryShiftManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftManifestStore: ShiftManifestStore {
        var inner: MemoryShiftManifestStore
        var cache: TTLCache<ShiftManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftManifestStore, cache: TTLCache<ShiftManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftManifest? {
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

        func save(_ item: ShiftManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftManifest] {
            return inner.list()
        }
    }

    static func newCachedShiftManifestStore(_ inner: MemoryShiftManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftManifestStore {
        return CachedShiftManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift manifests. Empty fields match all.
    final class ShiftManifestQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ShiftManifest]) -> [ShiftManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftManifests(_ store: any ShiftManifestStore, query: ShiftManifestQuery) -> [ShiftManifest] {
        return query.apply(store.list())
    }
}
