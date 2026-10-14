import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim notices by code.
    protocol ClaimNoticeStore {
        func find(_ code: String) -> ClaimNotice?
        func save(_ item: ClaimNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimNoticeStore: ClaimNoticeStore {
        var items: [String: ClaimNotice]
        var order: [String]

        init(items: [String: ClaimNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimNotice) {
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

        func list() -> [ClaimNotice] {
            var out: [ClaimNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimNoticeStore() -> any ClaimNoticeStore {
        return MemoryClaimNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimNoticeStore: ClaimNoticeStore {
        var inner: MemoryClaimNoticeStore
        var cache: TTLCache<ClaimNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimNoticeStore, cache: TTLCache<ClaimNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimNotice? {
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

        func save(_ item: ClaimNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimNotice] {
            return inner.list()
        }
    }

    static func newCachedClaimNoticeStore(_ inner: MemoryClaimNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimNoticeStore {
        return CachedClaimNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim notices. Empty fields match all.
    final class ClaimNoticeQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimNotice]) -> [ClaimNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimNotices(_ store: any ClaimNoticeStore, query: ClaimNoticeQuery) -> [ClaimNotice] {
        return query.apply(store.list())
    }
}
