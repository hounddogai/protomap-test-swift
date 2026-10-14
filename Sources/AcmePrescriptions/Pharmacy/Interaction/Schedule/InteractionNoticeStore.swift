import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction notices by code.
    protocol InteractionNoticeStore {
        func find(_ code: String) -> InteractionNotice?
        func save(_ item: InteractionNotice)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionNoticeStore: InteractionNoticeStore {
        var items: [String: InteractionNotice]
        var order: [String]

        init(items: [String: InteractionNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionNotice) {
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

        func list() -> [InteractionNotice] {
            var out: [InteractionNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionNoticeStore() -> any InteractionNoticeStore {
        return MemoryInteractionNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionNoticeStore: InteractionNoticeStore {
        var inner: MemoryInteractionNoticeStore
        var cache: TTLCache<InteractionNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionNoticeStore, cache: TTLCache<InteractionNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionNotice? {
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

        func save(_ item: InteractionNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionNotice] {
            return inner.list()
        }
    }

    static func newCachedInteractionNoticeStore(_ inner: MemoryInteractionNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionNoticeStore {
        return CachedInteractionNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction notices. Empty fields match all.
    final class InteractionNoticeQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionNotice) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionNotice]) -> [InteractionNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionNotices(_ store: any InteractionNoticeStore, query: InteractionNoticeQuery) -> [InteractionNotice] {
        return query.apply(store.list())
    }
}
