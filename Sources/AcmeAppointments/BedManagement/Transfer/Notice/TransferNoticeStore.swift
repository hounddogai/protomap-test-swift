import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer notices by code.
    protocol TransferNoticeStore {
        func find(_ code: String) -> TransferNotice?
        func save(_ item: TransferNotice)
        func remove(_ code: String) -> Bool
        func list() -> [TransferNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferNoticeStore: TransferNoticeStore {
        var items: [String: TransferNotice]
        var order: [String]

        init(items: [String: TransferNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferNotice) {
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

        func list() -> [TransferNotice] {
            var out: [TransferNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferNoticeStore() -> any TransferNoticeStore {
        return MemoryTransferNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferNoticeStore: TransferNoticeStore {
        var inner: MemoryTransferNoticeStore
        var cache: TTLCache<TransferNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferNoticeStore, cache: TTLCache<TransferNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferNotice? {
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

        func save(_ item: TransferNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferNotice] {
            return inner.list()
        }
    }

    static func newCachedTransferNoticeStore(_ inner: MemoryTransferNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferNoticeStore {
        return CachedTransferNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer notices. Empty fields match all.
    final class TransferNoticeQuery {
        var facility: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferNotice) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferNotice]) -> [TransferNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferNotices(_ store: any TransferNoticeStore, query: TransferNoticeQuery) -> [TransferNotice] {
        return query.apply(store.list())
    }
}
