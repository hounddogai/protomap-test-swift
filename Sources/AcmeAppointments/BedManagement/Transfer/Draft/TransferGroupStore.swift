import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer groups by code.
    protocol TransferGroupStore {
        func find(_ code: String) -> TransferGroup?
        func save(_ item: TransferGroup)
        func remove(_ code: String) -> Bool
        func list() -> [TransferGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferGroupStore: TransferGroupStore {
        var items: [String: TransferGroup]
        var order: [String]

        init(items: [String: TransferGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferGroup) {
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

        func list() -> [TransferGroup] {
            var out: [TransferGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferGroupStore() -> any TransferGroupStore {
        return MemoryTransferGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferGroupStore: TransferGroupStore {
        var inner: MemoryTransferGroupStore
        var cache: TTLCache<TransferGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferGroupStore, cache: TTLCache<TransferGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferGroup? {
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

        func save(_ item: TransferGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferGroup] {
            return inner.list()
        }
    }

    static func newCachedTransferGroupStore(_ inner: MemoryTransferGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferGroupStore {
        return CachedTransferGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer groups. Empty fields match all.
    final class TransferGroupQuery {
        var unit: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCopay: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferGroup]) -> [TransferGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferGroups(_ store: any TransferGroupStore, query: TransferGroupQuery) -> [TransferGroup] {
        return query.apply(store.list())
    }
}
