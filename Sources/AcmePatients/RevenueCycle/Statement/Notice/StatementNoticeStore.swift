import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement notices by code.
    protocol StatementNoticeStore {
        func find(_ code: String) -> StatementNotice?
        func save(_ item: StatementNotice)
        func remove(_ code: String) -> Bool
        func list() -> [StatementNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementNoticeStore: StatementNoticeStore {
        var items: [String: StatementNotice]
        var order: [String]

        init(items: [String: StatementNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementNotice) {
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

        func list() -> [StatementNotice] {
            var out: [StatementNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementNoticeStore() -> any StatementNoticeStore {
        return MemoryStatementNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementNoticeStore: StatementNoticeStore {
        var inner: MemoryStatementNoticeStore
        var cache: TTLCache<StatementNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementNoticeStore, cache: TTLCache<StatementNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementNotice? {
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

        func save(_ item: StatementNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementNotice] {
            return inner.list()
        }
    }

    static func newCachedStatementNoticeStore(_ inner: MemoryStatementNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementNoticeStore {
        return CachedStatementNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement notices. Empty fields match all.
    final class StatementNoticeQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementNotice) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementNotice]) -> [StatementNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementNotices(_ store: any StatementNoticeStore, query: StatementNoticeQuery) -> [StatementNotice] {
        return query.apply(store.list())
    }
}
