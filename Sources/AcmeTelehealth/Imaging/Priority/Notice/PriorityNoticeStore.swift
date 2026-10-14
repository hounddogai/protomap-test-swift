import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority notices by code.
    protocol PriorityNoticeStore {
        func find(_ code: String) -> PriorityNotice?
        func save(_ item: PriorityNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityNoticeStore: PriorityNoticeStore {
        var items: [String: PriorityNotice]
        var order: [String]

        init(items: [String: PriorityNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityNotice) {
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

        func list() -> [PriorityNotice] {
            var out: [PriorityNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityNoticeStore() -> any PriorityNoticeStore {
        return MemoryPriorityNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityNoticeStore: PriorityNoticeStore {
        var inner: MemoryPriorityNoticeStore
        var cache: TTLCache<PriorityNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityNoticeStore, cache: TTLCache<PriorityNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityNotice? {
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

        func save(_ item: PriorityNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityNotice] {
            return inner.list()
        }
    }

    static func newCachedPriorityNoticeStore(_ inner: MemoryPriorityNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityNoticeStore {
        return CachedPriorityNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority notices. Empty fields match all.
    final class PriorityNoticeQuery {
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

        func matches(_ item: PriorityNotice) -> Bool {
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

        func apply(_ items: [PriorityNotice]) -> [PriorityNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityNotices(_ store: any PriorityNoticeStore, query: PriorityNoticeQuery) -> [PriorityNotice] {
        return query.apply(store.list())
    }
}
