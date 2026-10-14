import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession notices by code.
    protocol AccessionNoticeStore {
        func find(_ code: String) -> AccessionNotice?
        func save(_ item: AccessionNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionNoticeStore: AccessionNoticeStore {
        var items: [String: AccessionNotice]
        var order: [String]

        init(items: [String: AccessionNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionNotice) {
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

        func list() -> [AccessionNotice] {
            var out: [AccessionNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionNoticeStore() -> any AccessionNoticeStore {
        return MemoryAccessionNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionNoticeStore: AccessionNoticeStore {
        var inner: MemoryAccessionNoticeStore
        var cache: TTLCache<AccessionNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionNoticeStore, cache: TTLCache<AccessionNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionNotice? {
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

        func save(_ item: AccessionNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionNotice] {
            return inner.list()
        }
    }

    static func newCachedAccessionNoticeStore(_ inner: MemoryAccessionNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionNoticeStore {
        return CachedAccessionNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession notices. Empty fields match all.
    final class AccessionNoticeQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionNotice]) -> [AccessionNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionNotices(_ store: any AccessionNoticeStore, query: AccessionNoticeQuery) -> [AccessionNotice] {
        return query.apply(store.list())
    }
}
