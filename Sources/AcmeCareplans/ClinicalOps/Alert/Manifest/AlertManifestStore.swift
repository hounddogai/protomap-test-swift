import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert manifests by code.
    protocol AlertManifestStore {
        func find(_ code: String) -> AlertManifest?
        func save(_ item: AlertManifest)
        func remove(_ code: String) -> Bool
        func list() -> [AlertManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertManifestStore: AlertManifestStore {
        var items: [String: AlertManifest]
        var order: [String]

        init(items: [String: AlertManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertManifest) {
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

        func list() -> [AlertManifest] {
            var out: [AlertManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertManifestStore() -> any AlertManifestStore {
        return MemoryAlertManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertManifestStore: AlertManifestStore {
        var inner: MemoryAlertManifestStore
        var cache: TTLCache<AlertManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertManifestStore, cache: TTLCache<AlertManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertManifest? {
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

        func save(_ item: AlertManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertManifest] {
            return inner.list()
        }
    }

    static func newCachedAlertManifestStore(_ inner: MemoryAlertManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertManifestStore {
        return CachedAlertManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert manifests. Empty fields match all.
    final class AlertManifestQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertManifest]) -> [AlertManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertManifests(_ store: any AlertManifestStore, query: AlertManifestQuery) -> [AlertManifest] {
        return query.apply(store.list())
    }
}
