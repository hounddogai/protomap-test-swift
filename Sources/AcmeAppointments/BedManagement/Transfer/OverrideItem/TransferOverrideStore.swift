import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer overrides by code.
    protocol TransferOverrideStore {
        func find(_ code: String) -> TransferOverride?
        func save(_ item: TransferOverride)
        func remove(_ code: String) -> Bool
        func list() -> [TransferOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferOverrideStore: TransferOverrideStore {
        var items: [String: TransferOverride]
        var order: [String]

        init(items: [String: TransferOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferOverride) {
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

        func list() -> [TransferOverride] {
            var out: [TransferOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferOverrideStore() -> any TransferOverrideStore {
        return MemoryTransferOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferOverrideStore: TransferOverrideStore {
        var inner: MemoryTransferOverrideStore
        var cache: TTLCache<TransferOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferOverrideStore, cache: TTLCache<TransferOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferOverride? {
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

        func save(_ item: TransferOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferOverride] {
            return inner.list()
        }
    }

    static func newCachedTransferOverrideStore(_ inner: MemoryTransferOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferOverrideStore {
        return CachedTransferOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer overrides. Empty fields match all.
    final class TransferOverrideQuery {
        var facility: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMargin: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferOverride) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferOverride]) -> [TransferOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferOverrides(_ store: any TransferOverrideStore, query: TransferOverrideQuery) -> [TransferOverride] {
        return query.apply(store.list())
    }
}
