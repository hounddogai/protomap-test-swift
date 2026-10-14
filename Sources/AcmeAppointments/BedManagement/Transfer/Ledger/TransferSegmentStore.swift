import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer segments by code.
    protocol TransferSegmentStore {
        func find(_ code: String) -> TransferSegment?
        func save(_ item: TransferSegment)
        func remove(_ code: String) -> Bool
        func list() -> [TransferSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferSegmentStore: TransferSegmentStore {
        var items: [String: TransferSegment]
        var order: [String]

        init(items: [String: TransferSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferSegment) {
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

        func list() -> [TransferSegment] {
            var out: [TransferSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferSegmentStore() -> any TransferSegmentStore {
        return MemoryTransferSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferSegmentStore: TransferSegmentStore {
        var inner: MemoryTransferSegmentStore
        var cache: TTLCache<TransferSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferSegmentStore, cache: TTLCache<TransferSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferSegment? {
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

        func save(_ item: TransferSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferSegment] {
            return inner.list()
        }
    }

    static func newCachedTransferSegmentStore(_ inner: MemoryTransferSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferSegmentStore {
        return CachedTransferSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer segments. Empty fields match all.
    final class TransferSegmentQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferSegment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferSegment]) -> [TransferSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferSegments(_ store: any TransferSegmentStore, query: TransferSegmentQuery) -> [TransferSegment] {
        return query.apply(store.list())
    }
}
