import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending modality notices by code.
    protocol PendingModalityNoticeStore {
        func find(_ code: String) -> PendingModalityNotice?
        func save(_ item: PendingModalityNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PendingModalityNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingModalityNoticeStore: PendingModalityNoticeStore {
        var items: [String: PendingModalityNotice]
        var order: [String]

        init(items: [String: PendingModalityNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingModalityNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingModalityNotice) {
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

        func list() -> [PendingModalityNotice] {
            var out: [PendingModalityNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingModalityNoticeStore() -> any PendingModalityNoticeStore {
        return MemoryPendingModalityNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingModalityNoticeStore: PendingModalityNoticeStore {
        var inner: MemoryPendingModalityNoticeStore
        var cache: TTLCache<PendingModalityNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingModalityNoticeStore, cache: TTLCache<PendingModalityNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingModalityNotice? {
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

        func save(_ item: PendingModalityNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingModalityNotice] {
            return inner.list()
        }
    }

    static func newCachedPendingModalityNoticeStore(_ inner: MemoryPendingModalityNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingModalityNoticeStore {
        return CachedPendingModalityNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending modality notices. Empty fields match all.
    final class PendingModalityNoticeQuery {
        var country: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingModalityNotice) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingModalityNotice]) -> [PendingModalityNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingModalityNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingModalityNotices(_ store: any PendingModalityNoticeStore, query: PendingModalityNoticeQuery) -> [PendingModalityNotice] {
        return query.apply(store.list())
    }
}
