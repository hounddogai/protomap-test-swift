import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive inventory notices by code.
    protocol AdaptiveInventoryNoticeStore {
        func find(_ code: String) -> AdaptiveInventoryNotice?
        func save(_ item: AdaptiveInventoryNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveInventoryNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveInventoryNoticeStore: AdaptiveInventoryNoticeStore {
        var items: [String: AdaptiveInventoryNotice]
        var order: [String]

        init(items: [String: AdaptiveInventoryNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveInventoryNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveInventoryNotice) {
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

        func list() -> [AdaptiveInventoryNotice] {
            var out: [AdaptiveInventoryNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveInventoryNoticeStore() -> any AdaptiveInventoryNoticeStore {
        return MemoryAdaptiveInventoryNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveInventoryNoticeStore: AdaptiveInventoryNoticeStore {
        var inner: MemoryAdaptiveInventoryNoticeStore
        var cache: TTLCache<AdaptiveInventoryNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveInventoryNoticeStore, cache: TTLCache<AdaptiveInventoryNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveInventoryNotice? {
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

        func save(_ item: AdaptiveInventoryNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveInventoryNotice] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveInventoryNoticeStore(_ inner: MemoryAdaptiveInventoryNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveInventoryNoticeStore {
        return CachedAdaptiveInventoryNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive inventory notices. Empty fields match all.
    final class AdaptiveInventoryNoticeQuery {
        var country: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveInventoryNotice) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveInventoryNotice]) -> [AdaptiveInventoryNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveInventoryNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveInventoryNotices(_ store: any AdaptiveInventoryNoticeStore, query: AdaptiveInventoryNoticeQuery) -> [AdaptiveInventoryNotice] {
        return query.apply(store.list())
    }
}
