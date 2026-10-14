import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending inventory notices by code.
    protocol PendingInventoryNoticeStore {
        func find(_ code: String) -> PendingInventoryNotice?
        func save(_ item: PendingInventoryNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PendingInventoryNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingInventoryNoticeStore: PendingInventoryNoticeStore {
        var items: [String: PendingInventoryNotice]
        var order: [String]

        init(items: [String: PendingInventoryNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingInventoryNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingInventoryNotice) {
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

        func list() -> [PendingInventoryNotice] {
            var out: [PendingInventoryNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingInventoryNoticeStore() -> any PendingInventoryNoticeStore {
        return MemoryPendingInventoryNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingInventoryNoticeStore: PendingInventoryNoticeStore {
        var inner: MemoryPendingInventoryNoticeStore
        var cache: TTLCache<PendingInventoryNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingInventoryNoticeStore, cache: TTLCache<PendingInventoryNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingInventoryNotice? {
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

        func save(_ item: PendingInventoryNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingInventoryNotice] {
            return inner.list()
        }
    }

    static func newCachedPendingInventoryNoticeStore(_ inner: MemoryPendingInventoryNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingInventoryNoticeStore {
        return CachedPendingInventoryNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending inventory notices. Empty fields match all.
    final class PendingInventoryNoticeQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingInventoryNotice) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingInventoryNotice]) -> [PendingInventoryNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingInventoryNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingInventoryNotices(_ store: any PendingInventoryNoticeStore, query: PendingInventoryNoticeQuery) -> [PendingInventoryNotice] {
        return query.apply(store.list())
    }
}
