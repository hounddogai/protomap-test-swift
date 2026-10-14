import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal inventory notices by code.
    protocol SeasonalInventoryNoticeStore {
        func find(_ code: String) -> SeasonalInventoryNotice?
        func save(_ item: SeasonalInventoryNotice)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalInventoryNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalInventoryNoticeStore: SeasonalInventoryNoticeStore {
        var items: [String: SeasonalInventoryNotice]
        var order: [String]

        init(items: [String: SeasonalInventoryNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalInventoryNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalInventoryNotice) {
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

        func list() -> [SeasonalInventoryNotice] {
            var out: [SeasonalInventoryNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalInventoryNoticeStore() -> any SeasonalInventoryNoticeStore {
        return MemorySeasonalInventoryNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalInventoryNoticeStore: SeasonalInventoryNoticeStore {
        var inner: MemorySeasonalInventoryNoticeStore
        var cache: TTLCache<SeasonalInventoryNotice>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalInventoryNoticeStore, cache: TTLCache<SeasonalInventoryNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalInventoryNotice? {
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

        func save(_ item: SeasonalInventoryNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalInventoryNotice] {
            return inner.list()
        }
    }

    static func newCachedSeasonalInventoryNoticeStore(_ inner: MemorySeasonalInventoryNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalInventoryNoticeStore {
        return CachedSeasonalInventoryNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal inventory notices. Empty fields match all.
    final class SeasonalInventoryNoticeQuery {
        var region: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVersion: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalInventoryNotice) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalInventoryNotice]) -> [SeasonalInventoryNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalInventoryNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalInventoryNotices(_ store: any SeasonalInventoryNoticeStore, query: SeasonalInventoryNoticeQuery) -> [SeasonalInventoryNotice] {
        return query.apply(store.list())
    }
}
