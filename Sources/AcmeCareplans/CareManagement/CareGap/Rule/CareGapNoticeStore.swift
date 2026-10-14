import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap notices by code.
    protocol CareGapNoticeStore {
        func find(_ code: String) -> CareGapNotice?
        func save(_ item: CareGapNotice)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapNoticeStore: CareGapNoticeStore {
        var items: [String: CareGapNotice]
        var order: [String]

        init(items: [String: CareGapNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapNotice) {
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

        func list() -> [CareGapNotice] {
            var out: [CareGapNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapNoticeStore() -> any CareGapNoticeStore {
        return MemoryCareGapNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapNoticeStore: CareGapNoticeStore {
        var inner: MemoryCareGapNoticeStore
        var cache: TTLCache<CareGapNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapNoticeStore, cache: TTLCache<CareGapNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapNotice? {
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

        func save(_ item: CareGapNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapNotice] {
            return inner.list()
        }
    }

    static func newCachedCareGapNoticeStore(_ inner: MemoryCareGapNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapNoticeStore {
        return CachedCareGapNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap notices. Empty fields match all.
    final class CareGapNoticeQuery {
        var facility: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapNotice) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapNotice]) -> [CareGapNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapNotices(_ store: any CareGapNoticeStore, query: CareGapNoticeQuery) -> [CareGapNotice] {
        return query.apply(store.list())
    }
}
