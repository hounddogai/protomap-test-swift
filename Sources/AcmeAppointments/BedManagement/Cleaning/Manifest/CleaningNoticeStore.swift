import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning notices by code.
    protocol CleaningNoticeStore {
        func find(_ code: String) -> CleaningNotice?
        func save(_ item: CleaningNotice)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningNoticeStore: CleaningNoticeStore {
        var items: [String: CleaningNotice]
        var order: [String]

        init(items: [String: CleaningNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningNotice) {
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

        func list() -> [CleaningNotice] {
            var out: [CleaningNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningNoticeStore() -> any CleaningNoticeStore {
        return MemoryCleaningNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningNoticeStore: CleaningNoticeStore {
        var inner: MemoryCleaningNoticeStore
        var cache: TTLCache<CleaningNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningNoticeStore, cache: TTLCache<CleaningNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningNotice? {
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

        func save(_ item: CleaningNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningNotice] {
            return inner.list()
        }
    }

    static func newCachedCleaningNoticeStore(_ inner: MemoryCleaningNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningNoticeStore {
        return CachedCleaningNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning notices. Empty fields match all.
    final class CleaningNoticeQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningNotice) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningNotice]) -> [CleaningNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningNotices(_ store: any CleaningNoticeStore, query: CleaningNoticeQuery) -> [CleaningNotice] {
        return query.apply(store.list())
    }
}
