import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled accession notices by code.
    protocol ScheduledAccessionNoticeStore {
        func find(_ code: String) -> ScheduledAccessionNotice?
        func save(_ item: ScheduledAccessionNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAccessionNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAccessionNoticeStore: ScheduledAccessionNoticeStore {
        var items: [String: ScheduledAccessionNotice]
        var order: [String]

        init(items: [String: ScheduledAccessionNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAccessionNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAccessionNotice) {
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

        func list() -> [ScheduledAccessionNotice] {
            var out: [ScheduledAccessionNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAccessionNoticeStore() -> any ScheduledAccessionNoticeStore {
        return MemoryScheduledAccessionNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAccessionNoticeStore: ScheduledAccessionNoticeStore {
        var inner: MemoryScheduledAccessionNoticeStore
        var cache: TTLCache<ScheduledAccessionNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAccessionNoticeStore, cache: TTLCache<ScheduledAccessionNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAccessionNotice? {
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

        func save(_ item: ScheduledAccessionNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAccessionNotice] {
            return inner.list()
        }
    }

    static func newCachedScheduledAccessionNoticeStore(_ inner: MemoryScheduledAccessionNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAccessionNoticeStore {
        return CachedScheduledAccessionNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled accession notices. Empty fields match all.
    final class ScheduledAccessionNoticeQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAccessionNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledAccessionNotice]) -> [ScheduledAccessionNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAccessionNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAccessionNotices(_ store: any ScheduledAccessionNoticeStore, query: ScheduledAccessionNoticeQuery) -> [ScheduledAccessionNotice] {
        return query.apply(store.list())
    }
}
