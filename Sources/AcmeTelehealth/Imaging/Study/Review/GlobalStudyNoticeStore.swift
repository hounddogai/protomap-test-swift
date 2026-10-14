import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global study notices by code.
    protocol GlobalStudyNoticeStore {
        func find(_ code: String) -> GlobalStudyNotice?
        func save(_ item: GlobalStudyNotice)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalStudyNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalStudyNoticeStore: GlobalStudyNoticeStore {
        var items: [String: GlobalStudyNotice]
        var order: [String]

        init(items: [String: GlobalStudyNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalStudyNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalStudyNotice) {
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

        func list() -> [GlobalStudyNotice] {
            var out: [GlobalStudyNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalStudyNoticeStore() -> any GlobalStudyNoticeStore {
        return MemoryGlobalStudyNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalStudyNoticeStore: GlobalStudyNoticeStore {
        var inner: MemoryGlobalStudyNoticeStore
        var cache: TTLCache<GlobalStudyNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalStudyNoticeStore, cache: TTLCache<GlobalStudyNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalStudyNotice? {
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

        func save(_ item: GlobalStudyNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalStudyNotice] {
            return inner.list()
        }
    }

    static func newCachedGlobalStudyNoticeStore(_ inner: MemoryGlobalStudyNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalStudyNoticeStore {
        return CachedGlobalStudyNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global study notices. Empty fields match all.
    final class GlobalStudyNoticeQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalStudyNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalStudyNotice]) -> [GlobalStudyNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalStudyNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalStudyNotices(_ store: any GlobalStudyNoticeStore, query: GlobalStudyNoticeQuery) -> [GlobalStudyNotice] {
        return query.apply(store.list())
    }
}
