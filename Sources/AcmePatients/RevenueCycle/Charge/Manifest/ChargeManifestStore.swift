import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge manifests by code.
    protocol ChargeManifestStore {
        func find(_ code: String) -> ChargeManifest?
        func save(_ item: ChargeManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeManifestStore: ChargeManifestStore {
        var items: [String: ChargeManifest]
        var order: [String]

        init(items: [String: ChargeManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeManifest) {
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

        func list() -> [ChargeManifest] {
            var out: [ChargeManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeManifestStore() -> any ChargeManifestStore {
        return MemoryChargeManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeManifestStore: ChargeManifestStore {
        var inner: MemoryChargeManifestStore
        var cache: TTLCache<ChargeManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeManifestStore, cache: TTLCache<ChargeManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeManifest? {
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

        func save(_ item: ChargeManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeManifest] {
            return inner.list()
        }
    }

    static func newCachedChargeManifestStore(_ inner: MemoryChargeManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeManifestStore {
        return CachedChargeManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge manifests. Empty fields match all.
    final class ChargeManifestQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeManifest]) -> [ChargeManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeManifests(_ store: any ChargeManifestStore, query: ChargeManifestQuery) -> [ChargeManifest] {
        return query.apply(store.list())
    }
}
