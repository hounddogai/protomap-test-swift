import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up notices by code.
    protocol FollowUpNoticeStore {
        func find(_ code: String) -> FollowUpNotice?
        func save(_ item: FollowUpNotice)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpNoticeStore: FollowUpNoticeStore {
        var items: [String: FollowUpNotice]
        var order: [String]

        init(items: [String: FollowUpNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpNotice) {
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

        func list() -> [FollowUpNotice] {
            var out: [FollowUpNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpNoticeStore() -> any FollowUpNoticeStore {
        return MemoryFollowUpNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpNoticeStore: FollowUpNoticeStore {
        var inner: MemoryFollowUpNoticeStore
        var cache: TTLCache<FollowUpNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpNoticeStore, cache: TTLCache<FollowUpNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpNotice? {
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

        func save(_ item: FollowUpNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpNotice] {
            return inner.list()
        }
    }

    static func newCachedFollowUpNoticeStore(_ inner: MemoryFollowUpNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpNoticeStore {
        return CachedFollowUpNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up notices. Empty fields match all.
    final class FollowUpNoticeQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpNotice]) -> [FollowUpNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpNotices(_ store: any FollowUpNoticeStore, query: FollowUpNoticeQuery) -> [FollowUpNotice] {
        return query.apply(store.list())
    }
}
