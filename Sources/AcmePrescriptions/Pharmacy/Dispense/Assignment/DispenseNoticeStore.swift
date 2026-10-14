import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense notices by code.
    protocol DispenseNoticeStore {
        func find(_ code: String) -> DispenseNotice?
        func save(_ item: DispenseNotice)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseNoticeStore: DispenseNoticeStore {
        var items: [String: DispenseNotice]
        var order: [String]

        init(items: [String: DispenseNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseNotice) {
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

        func list() -> [DispenseNotice] {
            var out: [DispenseNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseNoticeStore() -> any DispenseNoticeStore {
        return MemoryDispenseNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseNoticeStore: DispenseNoticeStore {
        var inner: MemoryDispenseNoticeStore
        var cache: TTLCache<DispenseNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseNoticeStore, cache: TTLCache<DispenseNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseNotice? {
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

        func save(_ item: DispenseNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseNotice] {
            return inner.list()
        }
    }

    static func newCachedDispenseNoticeStore(_ inner: MemoryDispenseNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseNoticeStore {
        return CachedDispenseNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense notices. Empty fields match all.
    final class DispenseNoticeQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseNotice]) -> [DispenseNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseNotices(_ store: any DispenseNoticeStore, query: DispenseNoticeQuery) -> [DispenseNotice] {
        return query.apply(store.list())
    }
}
