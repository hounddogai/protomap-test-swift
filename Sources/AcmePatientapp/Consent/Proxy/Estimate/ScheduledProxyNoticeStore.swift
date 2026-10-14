import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled proxy notices by code.
    protocol ScheduledProxyNoticeStore {
        func find(_ code: String) -> ScheduledProxyNotice?
        func save(_ item: ScheduledProxyNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledProxyNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledProxyNoticeStore: ScheduledProxyNoticeStore {
        var items: [String: ScheduledProxyNotice]
        var order: [String]

        init(items: [String: ScheduledProxyNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledProxyNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledProxyNotice) {
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

        func list() -> [ScheduledProxyNotice] {
            var out: [ScheduledProxyNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledProxyNoticeStore() -> any ScheduledProxyNoticeStore {
        return MemoryScheduledProxyNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledProxyNoticeStore: ScheduledProxyNoticeStore {
        var inner: MemoryScheduledProxyNoticeStore
        var cache: TTLCache<ScheduledProxyNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledProxyNoticeStore, cache: TTLCache<ScheduledProxyNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledProxyNotice? {
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

        func save(_ item: ScheduledProxyNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledProxyNotice] {
            return inner.list()
        }
    }

    static func newCachedScheduledProxyNoticeStore(_ inner: MemoryScheduledProxyNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledProxyNoticeStore {
        return CachedScheduledProxyNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled proxy notices. Empty fields match all.
    final class ScheduledProxyNoticeQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledProxyNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledProxyNotice]) -> [ScheduledProxyNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledProxyNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledProxyNotices(_ store: any ScheduledProxyNoticeStore, query: ScheduledProxyNoticeQuery) -> [ScheduledProxyNotice] {
        return query.apply(store.list())
    }
}
