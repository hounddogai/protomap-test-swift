import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient closure notices by code.
    protocol LenientClosureNoticeStore {
        func find(_ code: String) -> LenientClosureNotice?
        func save(_ item: LenientClosureNotice)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClosureNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClosureNoticeStore: LenientClosureNoticeStore {
        var items: [String: LenientClosureNotice]
        var order: [String]

        init(items: [String: LenientClosureNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClosureNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClosureNotice) {
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

        func list() -> [LenientClosureNotice] {
            var out: [LenientClosureNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClosureNoticeStore() -> any LenientClosureNoticeStore {
        return MemoryLenientClosureNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClosureNoticeStore: LenientClosureNoticeStore {
        var inner: MemoryLenientClosureNoticeStore
        var cache: TTLCache<LenientClosureNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClosureNoticeStore, cache: TTLCache<LenientClosureNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClosureNotice? {
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

        func save(_ item: LenientClosureNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClosureNotice] {
            return inner.list()
        }
    }

    static func newCachedLenientClosureNoticeStore(_ inner: MemoryLenientClosureNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClosureNoticeStore {
        return CachedLenientClosureNoticeStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient closure notices. Empty fields match all.
    final class LenientClosureNoticeQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClosureNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientClosureNotice]) -> [LenientClosureNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClosureNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClosureNotices(_ store: any LenientClosureNoticeStore, query: LenientClosureNoticeQuery) -> [LenientClosureNotice] {
        return query.apply(store.list())
    }
}
