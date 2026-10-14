import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure notices by code.
    protocol ClosureNoticeStore {
        func find(_ code: String) -> ClosureNotice?
        func save(_ item: ClosureNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureNoticeStore: ClosureNoticeStore {
        var items: [String: ClosureNotice]
        var order: [String]

        init(items: [String: ClosureNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureNotice) {
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

        func list() -> [ClosureNotice] {
            var out: [ClosureNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureNoticeStore() -> any ClosureNoticeStore {
        return MemoryClosureNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureNoticeStore: ClosureNoticeStore {
        var inner: MemoryClosureNoticeStore
        var cache: TTLCache<ClosureNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureNoticeStore, cache: TTLCache<ClosureNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureNotice? {
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

        func save(_ item: ClosureNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureNotice] {
            return inner.list()
        }
    }

    static func newCachedClosureNoticeStore(_ inner: MemoryClosureNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureNoticeStore {
        return CachedClosureNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure notices. Empty fields match all.
    final class ClosureNoticeQuery {
        var ward: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRefills: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureNotice) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureNotice]) -> [ClosureNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureNotices(_ store: any ClosureNoticeStore, query: ClosureNoticeQuery) -> [ClosureNotice] {
        return query.apply(store.list())
    }
}
