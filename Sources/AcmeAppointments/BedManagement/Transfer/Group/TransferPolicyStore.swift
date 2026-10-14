import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer policies by code.
    protocol TransferPolicyStore {
        func find(_ code: String) -> TransferPolicy?
        func save(_ item: TransferPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [TransferPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferPolicyStore: TransferPolicyStore {
        var items: [String: TransferPolicy]
        var order: [String]

        init(items: [String: TransferPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferPolicy) {
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

        func list() -> [TransferPolicy] {
            var out: [TransferPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferPolicyStore() -> any TransferPolicyStore {
        return MemoryTransferPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferPolicyStore: TransferPolicyStore {
        var inner: MemoryTransferPolicyStore
        var cache: TTLCache<TransferPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferPolicyStore, cache: TTLCache<TransferPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferPolicy? {
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

        func save(_ item: TransferPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferPolicy] {
            return inner.list()
        }
    }

    static func newCachedTransferPolicyStore(_ inner: MemoryTransferPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferPolicyStore {
        return CachedTransferPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer policies. Empty fields match all.
    final class TransferPolicyQuery {
        var facility: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferPolicy) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [TransferPolicy]) -> [TransferPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferPolicies(_ store: any TransferPolicyStore, query: TransferPolicyQuery) -> [TransferPolicy] {
        return query.apply(store.list())
    }
}
