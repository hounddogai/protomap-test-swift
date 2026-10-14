import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending care gap notices by code.
    protocol PendingCareGapNoticeStore {
        func find(_ code: String) -> PendingCareGapNotice?
        func save(_ item: PendingCareGapNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCareGapNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCareGapNoticeStore: PendingCareGapNoticeStore {
        var items: [String: PendingCareGapNotice]
        var order: [String]

        init(items: [String: PendingCareGapNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCareGapNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCareGapNotice) {
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

        func list() -> [PendingCareGapNotice] {
            var out: [PendingCareGapNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCareGapNoticeStore() -> any PendingCareGapNoticeStore {
        return MemoryPendingCareGapNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCareGapNoticeStore: PendingCareGapNoticeStore {
        var inner: MemoryPendingCareGapNoticeStore
        var cache: TTLCache<PendingCareGapNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCareGapNoticeStore, cache: TTLCache<PendingCareGapNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCareGapNotice? {
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

        func save(_ item: PendingCareGapNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCareGapNotice] {
            return inner.list()
        }
    }

    static func newCachedPendingCareGapNoticeStore(_ inner: MemoryPendingCareGapNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCareGapNoticeStore {
        return CachedPendingCareGapNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending care gap notices. Empty fields match all.
    final class PendingCareGapNoticeQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCareGapNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCareGapNotice]) -> [PendingCareGapNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCareGapNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCareGapNotices(_ store: any PendingCareGapNoticeStore, query: PendingCareGapNoticeQuery) -> [PendingCareGapNotice] {
        return query.apply(store.list())
    }
}
