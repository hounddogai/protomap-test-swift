import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy overtime manifests by code.
    protocol LegacyOvertimeManifestStore {
        func find(_ code: String) -> LegacyOvertimeManifest?
        func save(_ item: LegacyOvertimeManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyOvertimeManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyOvertimeManifestStore: LegacyOvertimeManifestStore {
        var items: [String: LegacyOvertimeManifest]
        var order: [String]

        init(items: [String: LegacyOvertimeManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyOvertimeManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyOvertimeManifest) {
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

        func list() -> [LegacyOvertimeManifest] {
            var out: [LegacyOvertimeManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyOvertimeManifestStore() -> any LegacyOvertimeManifestStore {
        return MemoryLegacyOvertimeManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyOvertimeManifestStore: LegacyOvertimeManifestStore {
        var inner: MemoryLegacyOvertimeManifestStore
        var cache: TTLCache<LegacyOvertimeManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyOvertimeManifestStore, cache: TTLCache<LegacyOvertimeManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyOvertimeManifest? {
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

        func save(_ item: LegacyOvertimeManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyOvertimeManifest] {
            return inner.list()
        }
    }

    static func newCachedLegacyOvertimeManifestStore(_ inner: MemoryLegacyOvertimeManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyOvertimeManifestStore {
        return CachedLegacyOvertimeManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy overtime manifests. Empty fields match all.
    final class LegacyOvertimeManifestQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyOvertimeManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyOvertimeManifest]) -> [LegacyOvertimeManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyOvertimeManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyOvertimeManifests(_ store: any LegacyOvertimeManifestStore, query: LegacyOvertimeManifestQuery) -> [LegacyOvertimeManifest] {
        return query.apply(store.list())
    }
}
