import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive shift notices by code.
    protocol AdaptiveShiftNoticeStore {
        func find(_ code: String) -> AdaptiveShiftNotice?
        func save(_ item: AdaptiveShiftNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveShiftNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveShiftNoticeStore: AdaptiveShiftNoticeStore {
        var items: [String: AdaptiveShiftNotice]
        var order: [String]

        init(items: [String: AdaptiveShiftNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveShiftNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveShiftNotice) {
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

        func list() -> [AdaptiveShiftNotice] {
            var out: [AdaptiveShiftNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveShiftNoticeStore() -> any AdaptiveShiftNoticeStore {
        return MemoryAdaptiveShiftNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveShiftNoticeStore: AdaptiveShiftNoticeStore {
        var inner: MemoryAdaptiveShiftNoticeStore
        var cache: TTLCache<AdaptiveShiftNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveShiftNoticeStore, cache: TTLCache<AdaptiveShiftNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveShiftNotice? {
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

        func save(_ item: AdaptiveShiftNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveShiftNotice] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveShiftNoticeStore(_ inner: MemoryAdaptiveShiftNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveShiftNoticeStore {
        return CachedAdaptiveShiftNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive shift notices. Empty fields match all.
    final class AdaptiveShiftNoticeQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveShiftNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveShiftNotice]) -> [AdaptiveShiftNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveShiftNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveShiftNotices(_ store: any AdaptiveShiftNoticeStore, query: AdaptiveShiftNoticeQuery) -> [AdaptiveShiftNotice] {
        return query.apply(store.list())
    }
}
