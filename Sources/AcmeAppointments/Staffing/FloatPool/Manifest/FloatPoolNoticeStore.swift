import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool notices by code.
    protocol FloatPoolNoticeStore {
        func find(_ code: String) -> FloatPoolNotice?
        func save(_ item: FloatPoolNotice)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolNoticeStore: FloatPoolNoticeStore {
        var items: [String: FloatPoolNotice]
        var order: [String]

        init(items: [String: FloatPoolNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolNotice) {
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

        func list() -> [FloatPoolNotice] {
            var out: [FloatPoolNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolNoticeStore() -> any FloatPoolNoticeStore {
        return MemoryFloatPoolNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolNoticeStore: FloatPoolNoticeStore {
        var inner: MemoryFloatPoolNoticeStore
        var cache: TTLCache<FloatPoolNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolNoticeStore, cache: TTLCache<FloatPoolNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolNotice? {
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

        func save(_ item: FloatPoolNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolNotice] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolNoticeStore(_ inner: MemoryFloatPoolNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolNoticeStore {
        return CachedFloatPoolNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool notices. Empty fields match all.
    final class FloatPoolNoticeQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolNotice) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [FloatPoolNotice]) -> [FloatPoolNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolNotices(_ store: any FloatPoolNoticeStore, query: FloatPoolNoticeQuery) -> [FloatPoolNotice] {
        return query.apply(store.list())
    }
}
