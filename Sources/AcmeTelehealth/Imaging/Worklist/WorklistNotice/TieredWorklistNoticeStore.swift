import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered worklist notices by code.
    protocol TieredWorklistNoticeStore {
        func find(_ code: String) -> TieredWorklistNotice?
        func save(_ item: TieredWorklistNotice)
        func remove(_ code: String) -> Bool
        func list() -> [TieredWorklistNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredWorklistNoticeStore: TieredWorklistNoticeStore {
        var items: [String: TieredWorklistNotice]
        var order: [String]

        init(items: [String: TieredWorklistNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredWorklistNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredWorklistNotice) {
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

        func list() -> [TieredWorklistNotice] {
            var out: [TieredWorklistNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredWorklistNoticeStore() -> any TieredWorklistNoticeStore {
        return MemoryTieredWorklistNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredWorklistNoticeStore: TieredWorklistNoticeStore {
        var inner: MemoryTieredWorklistNoticeStore
        var cache: TTLCache<TieredWorklistNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredWorklistNoticeStore, cache: TTLCache<TieredWorklistNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredWorklistNotice? {
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

        func save(_ item: TieredWorklistNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredWorklistNotice] {
            return inner.list()
        }
    }

    static func newCachedTieredWorklistNoticeStore(_ inner: MemoryTieredWorklistNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredWorklistNoticeStore {
        return CachedTieredWorklistNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered worklist notices. Empty fields match all.
    final class TieredWorklistNoticeQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredWorklistNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredWorklistNotice]) -> [TieredWorklistNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredWorklistNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredWorklistNotices(_ store: any TieredWorklistNoticeStore, query: TieredWorklistNoticeQuery) -> [TieredWorklistNotice] {
        return query.apply(store.list())
    }
}
