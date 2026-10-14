import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer requests by code.
    protocol TransferRequestStore {
        func find(_ code: String) -> TransferRequest?
        func save(_ item: TransferRequest)
        func remove(_ code: String) -> Bool
        func list() -> [TransferRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferRequestStore: TransferRequestStore {
        var items: [String: TransferRequest]
        var order: [String]

        init(items: [String: TransferRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferRequest) {
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

        func list() -> [TransferRequest] {
            var out: [TransferRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferRequestStore() -> any TransferRequestStore {
        return MemoryTransferRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferRequestStore: TransferRequestStore {
        var inner: MemoryTransferRequestStore
        var cache: TTLCache<TransferRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferRequestStore, cache: TTLCache<TransferRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferRequest? {
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

        func save(_ item: TransferRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferRequest] {
            return inner.list()
        }
    }

    static func newCachedTransferRequestStore(_ inner: MemoryTransferRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferRequestStore {
        return CachedTransferRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer requests. Empty fields match all.
    final class TransferRequestQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [TransferRequest]) -> [TransferRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferRequests(_ store: any TransferRequestStore, query: TransferRequestQuery) -> [TransferRequest] {
        return query.apply(store.list())
    }
}
