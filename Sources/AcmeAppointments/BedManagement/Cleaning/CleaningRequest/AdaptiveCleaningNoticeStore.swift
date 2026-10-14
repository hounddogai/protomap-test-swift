import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive cleaning notices by code.
    protocol AdaptiveCleaningNoticeStore {
        func find(_ code: String) -> AdaptiveCleaningNotice?
        func save(_ item: AdaptiveCleaningNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCleaningNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCleaningNoticeStore: AdaptiveCleaningNoticeStore {
        var items: [String: AdaptiveCleaningNotice]
        var order: [String]

        init(items: [String: AdaptiveCleaningNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCleaningNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCleaningNotice) {
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

        func list() -> [AdaptiveCleaningNotice] {
            var out: [AdaptiveCleaningNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCleaningNoticeStore() -> any AdaptiveCleaningNoticeStore {
        return MemoryAdaptiveCleaningNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCleaningNoticeStore: AdaptiveCleaningNoticeStore {
        var inner: MemoryAdaptiveCleaningNoticeStore
        var cache: TTLCache<AdaptiveCleaningNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCleaningNoticeStore, cache: TTLCache<AdaptiveCleaningNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCleaningNotice? {
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

        func save(_ item: AdaptiveCleaningNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCleaningNotice] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCleaningNoticeStore(_ inner: MemoryAdaptiveCleaningNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCleaningNoticeStore {
        return CachedAdaptiveCleaningNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive cleaning notices. Empty fields match all.
    final class AdaptiveCleaningNoticeQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCleaningNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCleaningNotice]) -> [AdaptiveCleaningNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCleaningNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCleaningNotices(_ store: any AdaptiveCleaningNoticeStore, query: AdaptiveCleaningNoticeQuery) -> [AdaptiveCleaningNotice] {
        return query.apply(store.list())
    }
}
