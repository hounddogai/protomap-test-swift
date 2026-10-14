import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive follow up notices by code.
    protocol AdaptiveFollowUpNoticeStore {
        func find(_ code: String) -> AdaptiveFollowUpNotice?
        func save(_ item: AdaptiveFollowUpNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFollowUpNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFollowUpNoticeStore: AdaptiveFollowUpNoticeStore {
        var items: [String: AdaptiveFollowUpNotice]
        var order: [String]

        init(items: [String: AdaptiveFollowUpNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFollowUpNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFollowUpNotice) {
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

        func list() -> [AdaptiveFollowUpNotice] {
            var out: [AdaptiveFollowUpNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFollowUpNoticeStore() -> any AdaptiveFollowUpNoticeStore {
        return MemoryAdaptiveFollowUpNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFollowUpNoticeStore: AdaptiveFollowUpNoticeStore {
        var inner: MemoryAdaptiveFollowUpNoticeStore
        var cache: TTLCache<AdaptiveFollowUpNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFollowUpNoticeStore, cache: TTLCache<AdaptiveFollowUpNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFollowUpNotice? {
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

        func save(_ item: AdaptiveFollowUpNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFollowUpNotice] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFollowUpNoticeStore(_ inner: MemoryAdaptiveFollowUpNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFollowUpNoticeStore {
        return CachedAdaptiveFollowUpNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive follow up notices. Empty fields match all.
    final class AdaptiveFollowUpNoticeQuery {
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

        func matches(_ item: AdaptiveFollowUpNotice) -> Bool {
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

        func apply(_ items: [AdaptiveFollowUpNotice]) -> [AdaptiveFollowUpNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFollowUpNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFollowUpNotices(_ store: any AdaptiveFollowUpNoticeStore, query: AdaptiveFollowUpNoticeQuery) -> [AdaptiveFollowUpNotice] {
        return query.apply(store.list())
    }
}
