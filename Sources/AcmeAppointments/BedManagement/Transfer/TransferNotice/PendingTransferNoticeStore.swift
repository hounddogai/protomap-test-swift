import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending transfer notices by code.
    protocol PendingTransferNoticeStore {
        func find(_ code: String) -> PendingTransferNotice?
        func save(_ item: PendingTransferNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PendingTransferNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingTransferNoticeStore: PendingTransferNoticeStore {
        var items: [String: PendingTransferNotice]
        var order: [String]

        init(items: [String: PendingTransferNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingTransferNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingTransferNotice) {
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

        func list() -> [PendingTransferNotice] {
            var out: [PendingTransferNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingTransferNoticeStore() -> any PendingTransferNoticeStore {
        return MemoryPendingTransferNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingTransferNoticeStore: PendingTransferNoticeStore {
        var inner: MemoryPendingTransferNoticeStore
        var cache: TTLCache<PendingTransferNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingTransferNoticeStore, cache: TTLCache<PendingTransferNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingTransferNotice? {
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

        func save(_ item: PendingTransferNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingTransferNotice] {
            return inner.list()
        }
    }

    static func newCachedPendingTransferNoticeStore(_ inner: MemoryPendingTransferNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingTransferNoticeStore {
        return CachedPendingTransferNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending transfer notices. Empty fields match all.
    final class PendingTransferNoticeQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingTransferNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingTransferNotice]) -> [PendingTransferNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingTransferNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingTransferNotices(_ store: any PendingTransferNoticeStore, query: PendingTransferNoticeQuery) -> [PendingTransferNotice] {
        return query.apply(store.list())
    }
}
