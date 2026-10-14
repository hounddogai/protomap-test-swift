import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy handoff requests by code.
    protocol LegacyHandoffRequestStore {
        func find(_ code: String) -> LegacyHandoffRequest?
        func save(_ item: LegacyHandoffRequest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyHandoffRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyHandoffRequestStore: LegacyHandoffRequestStore {
        var items: [String: LegacyHandoffRequest]
        var order: [String]

        init(items: [String: LegacyHandoffRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyHandoffRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyHandoffRequest) {
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

        func list() -> [LegacyHandoffRequest] {
            var out: [LegacyHandoffRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyHandoffRequestStore() -> any LegacyHandoffRequestStore {
        return MemoryLegacyHandoffRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyHandoffRequestStore: LegacyHandoffRequestStore {
        var inner: MemoryLegacyHandoffRequestStore
        var cache: TTLCache<LegacyHandoffRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyHandoffRequestStore, cache: TTLCache<LegacyHandoffRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyHandoffRequest? {
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

        func save(_ item: LegacyHandoffRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyHandoffRequest] {
            return inner.list()
        }
    }

    static func newCachedLegacyHandoffRequestStore(_ inner: MemoryLegacyHandoffRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyHandoffRequestStore {
        return CachedLegacyHandoffRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy handoff requests. Empty fields match all.
    final class LegacyHandoffRequestQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyHandoffRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyHandoffRequest]) -> [LegacyHandoffRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyHandoffRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyHandoffRequests(_ store: any LegacyHandoffRequestStore, query: LegacyHandoffRequestQuery) -> [LegacyHandoffRequest] {
        return query.apply(store.list())
    }
}
