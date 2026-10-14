import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff manifests by code.
    protocol HandoffManifestStore {
        func find(_ code: String) -> HandoffManifest?
        func save(_ item: HandoffManifest)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffManifestStore: HandoffManifestStore {
        var items: [String: HandoffManifest]
        var order: [String]

        init(items: [String: HandoffManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffManifest) {
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

        func list() -> [HandoffManifest] {
            var out: [HandoffManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffManifestStore() -> any HandoffManifestStore {
        return MemoryHandoffManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffManifestStore: HandoffManifestStore {
        var inner: MemoryHandoffManifestStore
        var cache: TTLCache<HandoffManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffManifestStore, cache: TTLCache<HandoffManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffManifest? {
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

        func save(_ item: HandoffManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffManifest] {
            return inner.list()
        }
    }

    static func newCachedHandoffManifestStore(_ inner: MemoryHandoffManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffManifestStore {
        return CachedHandoffManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff manifests. Empty fields match all.
    final class HandoffManifestQuery {
        var unit: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minSequence: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffManifest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffManifest]) -> [HandoffManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffManifests(_ store: any HandoffManifestStore, query: HandoffManifestQuery) -> [HandoffManifest] {
        return query.apply(store.list())
    }
}
