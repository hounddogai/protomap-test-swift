import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer targets by code.
    protocol TransferTargetStore {
        func find(_ code: String) -> TransferTarget?
        func save(_ item: TransferTarget)
        func remove(_ code: String) -> Bool
        func list() -> [TransferTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferTargetStore: TransferTargetStore {
        var items: [String: TransferTarget]
        var order: [String]

        init(items: [String: TransferTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferTarget) {
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

        func list() -> [TransferTarget] {
            var out: [TransferTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferTargetStore() -> any TransferTargetStore {
        return MemoryTransferTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferTargetStore: TransferTargetStore {
        var inner: MemoryTransferTargetStore
        var cache: TTLCache<TransferTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferTargetStore, cache: TTLCache<TransferTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferTarget? {
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

        func save(_ item: TransferTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferTarget] {
            return inner.list()
        }
    }

    static func newCachedTransferTargetStore(_ inner: MemoryTransferTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferTargetStore {
        return CachedTransferTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer targets. Empty fields match all.
    final class TransferTargetQuery {
        var channel: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minWeight: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [TransferTarget]) -> [TransferTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferTargets(_ store: any TransferTargetStore, query: TransferTargetQuery) -> [TransferTarget] {
        return query.apply(store.list())
    }
}
