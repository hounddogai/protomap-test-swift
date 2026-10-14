import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential adjustments by code.
    protocol CredentialAdjustmentStore {
        func find(_ code: String) -> CredentialAdjustment?
        func save(_ item: CredentialAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialAdjustmentStore: CredentialAdjustmentStore {
        var items: [String: CredentialAdjustment]
        var order: [String]

        init(items: [String: CredentialAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialAdjustment) {
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

        func list() -> [CredentialAdjustment] {
            var out: [CredentialAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialAdjustmentStore() -> any CredentialAdjustmentStore {
        return MemoryCredentialAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialAdjustmentStore: CredentialAdjustmentStore {
        var inner: MemoryCredentialAdjustmentStore
        var cache: TTLCache<CredentialAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialAdjustmentStore, cache: TTLCache<CredentialAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialAdjustment? {
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

        func save(_ item: CredentialAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCredentialAdjustmentStore(_ inner: MemoryCredentialAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialAdjustmentStore {
        return CachedCredentialAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential adjustments. Empty fields match all.
    final class CredentialAdjustmentQuery {
        var facility: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minWeight: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialAdjustment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialAdjustment]) -> [CredentialAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialAdjustments(_ store: any CredentialAdjustmentStore, query: CredentialAdjustmentQuery) -> [CredentialAdjustment] {
        return query.apply(store.list())
    }
}
