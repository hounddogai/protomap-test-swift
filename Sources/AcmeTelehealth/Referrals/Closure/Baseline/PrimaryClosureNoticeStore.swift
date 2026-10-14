import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary closure notices by code.
    protocol PrimaryClosureNoticeStore {
        func find(_ code: String) -> PrimaryClosureNotice?
        func save(_ item: PrimaryClosureNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryClosureNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryClosureNoticeStore: PrimaryClosureNoticeStore {
        var items: [String: PrimaryClosureNotice]
        var order: [String]

        init(items: [String: PrimaryClosureNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryClosureNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryClosureNotice) {
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

        func list() -> [PrimaryClosureNotice] {
            var out: [PrimaryClosureNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryClosureNoticeStore() -> any PrimaryClosureNoticeStore {
        return MemoryPrimaryClosureNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryClosureNoticeStore: PrimaryClosureNoticeStore {
        var inner: MemoryPrimaryClosureNoticeStore
        var cache: TTLCache<PrimaryClosureNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryClosureNoticeStore, cache: TTLCache<PrimaryClosureNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryClosureNotice? {
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

        func save(_ item: PrimaryClosureNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryClosureNotice] {
            return inner.list()
        }
    }

    static func newCachedPrimaryClosureNoticeStore(_ inner: MemoryPrimaryClosureNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryClosureNoticeStore {
        return CachedPrimaryClosureNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary closure notices. Empty fields match all.
    final class PrimaryClosureNoticeQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryClosureNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryClosureNotice]) -> [PrimaryClosureNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryClosureNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryClosureNotices(_ store: any PrimaryClosureNoticeStore, query: PrimaryClosureNoticeQuery) -> [PrimaryClosureNotice] {
        return query.apply(store.list())
    }
}
