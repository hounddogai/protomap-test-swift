import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped closure notices by code.
    protocol CappedClosureNoticeStore {
        func find(_ code: String) -> CappedClosureNotice?
        func save(_ item: CappedClosureNotice)
        func remove(_ code: String) -> Bool
        func list() -> [CappedClosureNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedClosureNoticeStore: CappedClosureNoticeStore {
        var items: [String: CappedClosureNotice]
        var order: [String]

        init(items: [String: CappedClosureNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedClosureNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedClosureNotice) {
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

        func list() -> [CappedClosureNotice] {
            var out: [CappedClosureNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedClosureNoticeStore() -> any CappedClosureNoticeStore {
        return MemoryCappedClosureNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedClosureNoticeStore: CappedClosureNoticeStore {
        var inner: MemoryCappedClosureNoticeStore
        var cache: TTLCache<CappedClosureNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedClosureNoticeStore, cache: TTLCache<CappedClosureNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedClosureNotice? {
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

        func save(_ item: CappedClosureNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedClosureNotice] {
            return inner.list()
        }
    }

    static func newCachedCappedClosureNoticeStore(_ inner: MemoryCappedClosureNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedClosureNoticeStore {
        return CachedCappedClosureNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped closure notices. Empty fields match all.
    final class CappedClosureNoticeQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedClosureNotice) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedClosureNotice]) -> [CappedClosureNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedClosureNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedClosureNotices(_ store: any CappedClosureNoticeStore, query: CappedClosureNoticeQuery) -> [CappedClosureNotice] {
        return query.apply(store.list())
    }
}
