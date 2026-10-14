import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual formulary digests by code.
    protocol ManualFormularyDigestStore {
        func find(_ code: String) -> ManualFormularyDigest?
        func save(_ item: ManualFormularyDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualFormularyDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualFormularyDigestStore: ManualFormularyDigestStore {
        var items: [String: ManualFormularyDigest]
        var order: [String]

        init(items: [String: ManualFormularyDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualFormularyDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualFormularyDigest) {
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

        func list() -> [ManualFormularyDigest] {
            var out: [ManualFormularyDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualFormularyDigestStore() -> any ManualFormularyDigestStore {
        return MemoryManualFormularyDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualFormularyDigestStore: ManualFormularyDigestStore {
        var inner: MemoryManualFormularyDigestStore
        var cache: TTLCache<ManualFormularyDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualFormularyDigestStore, cache: TTLCache<ManualFormularyDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualFormularyDigest? {
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

        func save(_ item: ManualFormularyDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualFormularyDigest] {
            return inner.list()
        }
    }

    static func newCachedManualFormularyDigestStore(_ inner: MemoryManualFormularyDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualFormularyDigestStore {
        return CachedManualFormularyDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual formulary digests. Empty fields match all.
    final class ManualFormularyDigestQuery {
        var category: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualFormularyDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualFormularyDigest]) -> [ManualFormularyDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualFormularyDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualFormularyDigests(_ store: any ManualFormularyDigestStore, query: ManualFormularyDigestQuery) -> [ManualFormularyDigest] {
        return query.apply(store.list())
    }
}
