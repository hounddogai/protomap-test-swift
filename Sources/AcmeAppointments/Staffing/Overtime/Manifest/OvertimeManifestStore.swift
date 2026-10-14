import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime manifests by code.
    protocol OvertimeManifestStore {
        func find(_ code: String) -> OvertimeManifest?
        func save(_ item: OvertimeManifest)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeManifestStore: OvertimeManifestStore {
        var items: [String: OvertimeManifest]
        var order: [String]

        init(items: [String: OvertimeManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeManifest) {
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

        func list() -> [OvertimeManifest] {
            var out: [OvertimeManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeManifestStore() -> any OvertimeManifestStore {
        return MemoryOvertimeManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeManifestStore: OvertimeManifestStore {
        var inner: MemoryOvertimeManifestStore
        var cache: TTLCache<OvertimeManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeManifestStore, cache: TTLCache<OvertimeManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeManifest? {
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

        func save(_ item: OvertimeManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeManifest] {
            return inner.list()
        }
    }

    static func newCachedOvertimeManifestStore(_ inner: MemoryOvertimeManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeManifestStore {
        return CachedOvertimeManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime manifests. Empty fields match all.
    final class OvertimeManifestQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeManifest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [OvertimeManifest]) -> [OvertimeManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeManifests(_ store: any OvertimeManifestStore, query: OvertimeManifestQuery) -> [OvertimeManifest] {
        return query.apply(store.list())
    }
}
