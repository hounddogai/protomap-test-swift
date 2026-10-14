import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global care gap notices by code.
    protocol GlobalCareGapNoticeStore {
        func find(_ code: String) -> GlobalCareGapNotice?
        func save(_ item: GlobalCareGapNotice)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareGapNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareGapNoticeStore: GlobalCareGapNoticeStore {
        var items: [String: GlobalCareGapNotice]
        var order: [String]

        init(items: [String: GlobalCareGapNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareGapNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareGapNotice) {
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

        func list() -> [GlobalCareGapNotice] {
            var out: [GlobalCareGapNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareGapNoticeStore() -> any GlobalCareGapNoticeStore {
        return MemoryGlobalCareGapNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareGapNoticeStore: GlobalCareGapNoticeStore {
        var inner: MemoryGlobalCareGapNoticeStore
        var cache: TTLCache<GlobalCareGapNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareGapNoticeStore, cache: TTLCache<GlobalCareGapNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareGapNotice? {
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

        func save(_ item: GlobalCareGapNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareGapNotice] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareGapNoticeStore(_ inner: MemoryGlobalCareGapNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareGapNoticeStore {
        return CachedGlobalCareGapNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care gap notices. Empty fields match all.
    final class GlobalCareGapNoticeQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCareGapNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCareGapNotice]) -> [GlobalCareGapNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareGapNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareGapNotices(_ store: any GlobalCareGapNoticeStore, query: GlobalCareGapNoticeQuery) -> [GlobalCareGapNotice] {
        return query.apply(store.list())
    }
}
