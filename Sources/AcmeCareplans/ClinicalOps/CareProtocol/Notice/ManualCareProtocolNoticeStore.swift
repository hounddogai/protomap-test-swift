import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual care protocol notices by code.
    protocol ManualCareProtocolNoticeStore {
        func find(_ code: String) -> ManualCareProtocolNotice?
        func save(_ item: ManualCareProtocolNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolNoticeStore: ManualCareProtocolNoticeStore {
        var items: [String: ManualCareProtocolNotice]
        var order: [String]

        init(items: [String: ManualCareProtocolNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolNotice) {
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

        func list() -> [ManualCareProtocolNotice] {
            var out: [ManualCareProtocolNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolNoticeStore() -> any ManualCareProtocolNoticeStore {
        return MemoryManualCareProtocolNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolNoticeStore: ManualCareProtocolNoticeStore {
        var inner: MemoryManualCareProtocolNoticeStore
        var cache: TTLCache<ManualCareProtocolNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolNoticeStore, cache: TTLCache<ManualCareProtocolNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolNotice? {
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

        func save(_ item: ManualCareProtocolNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolNotice] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolNoticeStore(_ inner: MemoryManualCareProtocolNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolNoticeStore {
        return CachedManualCareProtocolNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol notices. Empty fields match all.
    final class ManualCareProtocolNoticeQuery {
        var category: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minPriority: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolNotice) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ManualCareProtocolNotice]) -> [ManualCareProtocolNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolNotices(_ store: any ManualCareProtocolNoticeStore, query: ManualCareProtocolNoticeQuery) -> [ManualCareProtocolNotice] {
        return query.apply(store.list())
    }
}
