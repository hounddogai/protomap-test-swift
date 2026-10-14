import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending follow up notices by code.
    protocol PendingFollowUpNoticeStore {
        func find(_ code: String) -> PendingFollowUpNotice?
        func save(_ item: PendingFollowUpNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFollowUpNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFollowUpNoticeStore: PendingFollowUpNoticeStore {
        var items: [String: PendingFollowUpNotice]
        var order: [String]

        init(items: [String: PendingFollowUpNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFollowUpNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFollowUpNotice) {
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

        func list() -> [PendingFollowUpNotice] {
            var out: [PendingFollowUpNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFollowUpNoticeStore() -> any PendingFollowUpNoticeStore {
        return MemoryPendingFollowUpNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFollowUpNoticeStore: PendingFollowUpNoticeStore {
        var inner: MemoryPendingFollowUpNoticeStore
        var cache: TTLCache<PendingFollowUpNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFollowUpNoticeStore, cache: TTLCache<PendingFollowUpNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFollowUpNotice? {
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

        func save(_ item: PendingFollowUpNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFollowUpNotice] {
            return inner.list()
        }
    }

    static func newCachedPendingFollowUpNoticeStore(_ inner: MemoryPendingFollowUpNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFollowUpNoticeStore {
        return CachedPendingFollowUpNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending follow up notices. Empty fields match all.
    final class PendingFollowUpNoticeQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFollowUpNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFollowUpNotice]) -> [PendingFollowUpNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFollowUpNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFollowUpNotices(_ store: any PendingFollowUpNoticeStore, query: PendingFollowUpNoticeQuery) -> [PendingFollowUpNotice] {
        return query.apply(store.list())
    }
}
