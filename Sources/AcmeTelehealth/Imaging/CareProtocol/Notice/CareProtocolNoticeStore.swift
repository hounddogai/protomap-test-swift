import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol notices by code.
    protocol CareProtocolNoticeStore {
        func find(_ code: String) -> CareProtocolNotice?
        func save(_ item: CareProtocolNotice)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolNoticeStore: CareProtocolNoticeStore {
        var items: [String: CareProtocolNotice]
        var order: [String]

        init(items: [String: CareProtocolNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolNotice) {
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

        func list() -> [CareProtocolNotice] {
            var out: [CareProtocolNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolNoticeStore() -> any CareProtocolNoticeStore {
        return MemoryCareProtocolNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolNoticeStore: CareProtocolNoticeStore {
        var inner: MemoryCareProtocolNoticeStore
        var cache: TTLCache<CareProtocolNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolNoticeStore, cache: TTLCache<CareProtocolNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolNotice? {
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

        func save(_ item: CareProtocolNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolNotice] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolNoticeStore(_ inner: MemoryCareProtocolNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolNoticeStore {
        return CachedCareProtocolNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol notices. Empty fields match all.
    final class CareProtocolNoticeQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolNotice) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolNotice]) -> [CareProtocolNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolNotices(_ store: any CareProtocolNoticeStore, query: CareProtocolNoticeQuery) -> [CareProtocolNotice] {
        return query.apply(store.list())
    }
}
