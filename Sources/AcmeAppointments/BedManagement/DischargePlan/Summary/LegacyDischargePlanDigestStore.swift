import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy discharge plan digests by code.
    protocol LegacyDischargePlanDigestStore {
        func find(_ code: String) -> LegacyDischargePlanDigest?
        func save(_ item: LegacyDischargePlanDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyDischargePlanDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyDischargePlanDigestStore: LegacyDischargePlanDigestStore {
        var items: [String: LegacyDischargePlanDigest]
        var order: [String]

        init(items: [String: LegacyDischargePlanDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyDischargePlanDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyDischargePlanDigest) {
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

        func list() -> [LegacyDischargePlanDigest] {
            var out: [LegacyDischargePlanDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyDischargePlanDigestStore() -> any LegacyDischargePlanDigestStore {
        return MemoryLegacyDischargePlanDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyDischargePlanDigestStore: LegacyDischargePlanDigestStore {
        var inner: MemoryLegacyDischargePlanDigestStore
        var cache: TTLCache<LegacyDischargePlanDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyDischargePlanDigestStore, cache: TTLCache<LegacyDischargePlanDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyDischargePlanDigest? {
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

        func save(_ item: LegacyDischargePlanDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyDischargePlanDigest] {
            return inner.list()
        }
    }

    static func newCachedLegacyDischargePlanDigestStore(_ inner: MemoryLegacyDischargePlanDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyDischargePlanDigestStore {
        return CachedLegacyDischargePlanDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy discharge plan digests. Empty fields match all.
    final class LegacyDischargePlanDigestQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyDischargePlanDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyDischargePlanDigest]) -> [LegacyDischargePlanDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyDischargePlanDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyDischargePlanDigests(_ store: any LegacyDischargePlanDigestStore, query: LegacyDischargePlanDigestQuery) -> [LegacyDischargePlanDigest] {
        return query.apply(store.list())
    }
}
