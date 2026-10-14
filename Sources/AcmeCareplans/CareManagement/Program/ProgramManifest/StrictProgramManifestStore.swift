import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict program manifests by code.
    protocol StrictProgramManifestStore {
        func find(_ code: String) -> StrictProgramManifest?
        func save(_ item: StrictProgramManifest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictProgramManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictProgramManifestStore: StrictProgramManifestStore {
        var items: [String: StrictProgramManifest]
        var order: [String]

        init(items: [String: StrictProgramManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictProgramManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictProgramManifest) {
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

        func list() -> [StrictProgramManifest] {
            var out: [StrictProgramManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictProgramManifestStore() -> any StrictProgramManifestStore {
        return MemoryStrictProgramManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictProgramManifestStore: StrictProgramManifestStore {
        var inner: MemoryStrictProgramManifestStore
        var cache: TTLCache<StrictProgramManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictProgramManifestStore, cache: TTLCache<StrictProgramManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictProgramManifest? {
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

        func save(_ item: StrictProgramManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictProgramManifest] {
            return inner.list()
        }
    }

    static func newCachedStrictProgramManifestStore(_ inner: MemoryStrictProgramManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictProgramManifestStore {
        return CachedStrictProgramManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict program manifests. Empty fields match all.
    final class StrictProgramManifestQuery {
        var unit: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictProgramManifest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictProgramManifest]) -> [StrictProgramManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictProgramManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictProgramManifests(_ store: any StrictProgramManifestStore, query: StrictProgramManifestQuery) -> [StrictProgramManifest] {
        return query.apply(store.list())
    }
}
