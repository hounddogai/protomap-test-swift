import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive worklist notices by code.
    protocol AdaptiveWorklistNoticeStore {
        func find(_ code: String) -> AdaptiveWorklistNotice?
        func save(_ item: AdaptiveWorklistNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveWorklistNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveWorklistNoticeStore: AdaptiveWorklistNoticeStore {
        var items: [String: AdaptiveWorklistNotice]
        var order: [String]

        init(items: [String: AdaptiveWorklistNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveWorklistNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveWorklistNotice) {
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

        func list() -> [AdaptiveWorklistNotice] {
            var out: [AdaptiveWorklistNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveWorklistNoticeStore() -> any AdaptiveWorklistNoticeStore {
        return MemoryAdaptiveWorklistNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveWorklistNoticeStore: AdaptiveWorklistNoticeStore {
        var inner: MemoryAdaptiveWorklistNoticeStore
        var cache: TTLCache<AdaptiveWorklistNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveWorklistNoticeStore, cache: TTLCache<AdaptiveWorklistNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveWorklistNotice? {
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

        func save(_ item: AdaptiveWorklistNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveWorklistNotice] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveWorklistNoticeStore(_ inner: MemoryAdaptiveWorklistNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveWorklistNoticeStore {
        return CachedAdaptiveWorklistNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive worklist notices. Empty fields match all.
    final class AdaptiveWorklistNoticeQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveWorklistNotice) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [AdaptiveWorklistNotice]) -> [AdaptiveWorklistNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveWorklistNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveWorklistNotices(_ store: any AdaptiveWorklistNoticeStore, query: AdaptiveWorklistNoticeQuery) -> [AdaptiveWorklistNotice] {
        return query.apply(store.list())
    }
}
