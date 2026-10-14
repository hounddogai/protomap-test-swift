import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure notices by code.
    protocol DisclosureNoticeStore {
        func find(_ code: String) -> DisclosureNotice?
        func save(_ item: DisclosureNotice)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureNoticeStore: DisclosureNoticeStore {
        var items: [String: DisclosureNotice]
        var order: [String]

        init(items: [String: DisclosureNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureNotice) {
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

        func list() -> [DisclosureNotice] {
            var out: [DisclosureNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureNoticeStore() -> any DisclosureNoticeStore {
        return MemoryDisclosureNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureNoticeStore: DisclosureNoticeStore {
        var inner: MemoryDisclosureNoticeStore
        var cache: TTLCache<DisclosureNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureNoticeStore, cache: TTLCache<DisclosureNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureNotice? {
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

        func save(_ item: DisclosureNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureNotice] {
            return inner.list()
        }
    }

    static func newCachedDisclosureNoticeStore(_ inner: MemoryDisclosureNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureNoticeStore {
        return CachedDisclosureNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure notices. Empty fields match all.
    final class DisclosureNoticeQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DisclosureNotice]) -> [DisclosureNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureNotices(_ store: any DisclosureNoticeStore, query: DisclosureNoticeQuery) -> [DisclosureNotice] {
        return query.apply(store.list())
    }
}
