import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient network notices by code.
    protocol LenientNetworkNoticeStore {
        func find(_ code: String) -> LenientNetworkNotice?
        func save(_ item: LenientNetworkNotice)
        func remove(_ code: String) -> Bool
        func list() -> [LenientNetworkNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientNetworkNoticeStore: LenientNetworkNoticeStore {
        var items: [String: LenientNetworkNotice]
        var order: [String]

        init(items: [String: LenientNetworkNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientNetworkNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientNetworkNotice) {
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

        func list() -> [LenientNetworkNotice] {
            var out: [LenientNetworkNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientNetworkNoticeStore() -> any LenientNetworkNoticeStore {
        return MemoryLenientNetworkNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientNetworkNoticeStore: LenientNetworkNoticeStore {
        var inner: MemoryLenientNetworkNoticeStore
        var cache: TTLCache<LenientNetworkNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientNetworkNoticeStore, cache: TTLCache<LenientNetworkNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientNetworkNotice? {
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

        func save(_ item: LenientNetworkNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientNetworkNotice] {
            return inner.list()
        }
    }

    static func newCachedLenientNetworkNoticeStore(_ inner: MemoryLenientNetworkNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientNetworkNoticeStore {
        return CachedLenientNetworkNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient network notices. Empty fields match all.
    final class LenientNetworkNoticeQuery {
        var unit: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientNetworkNotice) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientNetworkNotice]) -> [LenientNetworkNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientNetworkNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientNetworkNotices(_ store: any LenientNetworkNoticeStore, query: LenientNetworkNoticeQuery) -> [LenientNetworkNotice] {
        return query.apply(store.list())
    }
}
