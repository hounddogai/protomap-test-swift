import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary care gap notices by code.
    protocol PrimaryCareGapNoticeStore {
        func find(_ code: String) -> PrimaryCareGapNotice?
        func save(_ item: PrimaryCareGapNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCareGapNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCareGapNoticeStore: PrimaryCareGapNoticeStore {
        var items: [String: PrimaryCareGapNotice]
        var order: [String]

        init(items: [String: PrimaryCareGapNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCareGapNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCareGapNotice) {
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

        func list() -> [PrimaryCareGapNotice] {
            var out: [PrimaryCareGapNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCareGapNoticeStore() -> any PrimaryCareGapNoticeStore {
        return MemoryPrimaryCareGapNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCareGapNoticeStore: PrimaryCareGapNoticeStore {
        var inner: MemoryPrimaryCareGapNoticeStore
        var cache: TTLCache<PrimaryCareGapNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCareGapNoticeStore, cache: TTLCache<PrimaryCareGapNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCareGapNotice? {
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

        func save(_ item: PrimaryCareGapNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCareGapNotice] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCareGapNoticeStore(_ inner: MemoryPrimaryCareGapNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCareGapNoticeStore {
        return CachedPrimaryCareGapNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary care gap notices. Empty fields match all.
    final class PrimaryCareGapNoticeQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCareGapNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCareGapNotice]) -> [PrimaryCareGapNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCareGapNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCareGapNotices(_ store: any PrimaryCareGapNoticeStore, query: PrimaryCareGapNoticeQuery) -> [PrimaryCareGapNotice] {
        return query.apply(store.list())
    }
}
