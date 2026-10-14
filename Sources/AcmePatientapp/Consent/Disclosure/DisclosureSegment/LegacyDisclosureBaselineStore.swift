import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy disclosure baselines by code.
    protocol LegacyDisclosureBaselineStore {
        func find(_ code: String) -> LegacyDisclosureBaseline?
        func save(_ item: LegacyDisclosureBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyDisclosureBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyDisclosureBaselineStore: LegacyDisclosureBaselineStore {
        var items: [String: LegacyDisclosureBaseline]
        var order: [String]

        init(items: [String: LegacyDisclosureBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyDisclosureBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyDisclosureBaseline) {
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

        func list() -> [LegacyDisclosureBaseline] {
            var out: [LegacyDisclosureBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyDisclosureBaselineStore() -> any LegacyDisclosureBaselineStore {
        return MemoryLegacyDisclosureBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyDisclosureBaselineStore: LegacyDisclosureBaselineStore {
        var inner: MemoryLegacyDisclosureBaselineStore
        var cache: TTLCache<LegacyDisclosureBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyDisclosureBaselineStore, cache: TTLCache<LegacyDisclosureBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyDisclosureBaseline? {
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

        func save(_ item: LegacyDisclosureBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyDisclosureBaseline] {
            return inner.list()
        }
    }

    static func newCachedLegacyDisclosureBaselineStore(_ inner: MemoryLegacyDisclosureBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyDisclosureBaselineStore {
        return CachedLegacyDisclosureBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy disclosure baselines. Empty fields match all.
    final class LegacyDisclosureBaselineQuery {
        var facility: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minVersion: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyDisclosureBaseline) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyDisclosureBaseline]) -> [LegacyDisclosureBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyDisclosureBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyDisclosureBaselines(_ store: any LegacyDisclosureBaselineStore, query: LegacyDisclosureBaselineQuery) -> [LegacyDisclosureBaseline] {
        return query.apply(store.list())
    }
}
