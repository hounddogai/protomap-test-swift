import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped worklist notices by code.
    protocol CappedWorklistNoticeStore {
        func find(_ code: String) -> CappedWorklistNotice?
        func save(_ item: CappedWorklistNotice)
        func remove(_ code: String) -> Bool
        func list() -> [CappedWorklistNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedWorklistNoticeStore: CappedWorklistNoticeStore {
        var items: [String: CappedWorklistNotice]
        var order: [String]

        init(items: [String: CappedWorklistNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedWorklistNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedWorklistNotice) {
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

        func list() -> [CappedWorklistNotice] {
            var out: [CappedWorklistNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedWorklistNoticeStore() -> any CappedWorklistNoticeStore {
        return MemoryCappedWorklistNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedWorklistNoticeStore: CappedWorklistNoticeStore {
        var inner: MemoryCappedWorklistNoticeStore
        var cache: TTLCache<CappedWorklistNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedWorklistNoticeStore, cache: TTLCache<CappedWorklistNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedWorklistNotice? {
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

        func save(_ item: CappedWorklistNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedWorklistNotice] {
            return inner.list()
        }
    }

    static func newCachedCappedWorklistNoticeStore(_ inner: MemoryCappedWorklistNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedWorklistNoticeStore {
        return CachedCappedWorklistNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped worklist notices. Empty fields match all.
    final class CappedWorklistNoticeQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedWorklistNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedWorklistNotice]) -> [CappedWorklistNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedWorklistNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedWorklistNotices(_ store: any CappedWorklistNoticeStore, query: CappedWorklistNoticeQuery) -> [CappedWorklistNotice] {
        return query.apply(store.list())
    }
}
