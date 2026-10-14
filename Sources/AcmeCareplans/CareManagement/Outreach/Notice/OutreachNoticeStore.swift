import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach notices by code.
    protocol OutreachNoticeStore {
        func find(_ code: String) -> OutreachNotice?
        func save(_ item: OutreachNotice)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachNoticeStore: OutreachNoticeStore {
        var items: [String: OutreachNotice]
        var order: [String]

        init(items: [String: OutreachNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachNotice) {
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

        func list() -> [OutreachNotice] {
            var out: [OutreachNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachNoticeStore() -> any OutreachNoticeStore {
        return MemoryOutreachNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachNoticeStore: OutreachNoticeStore {
        var inner: MemoryOutreachNoticeStore
        var cache: TTLCache<OutreachNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachNoticeStore, cache: TTLCache<OutreachNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachNotice? {
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

        func save(_ item: OutreachNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachNotice] {
            return inner.list()
        }
    }

    static func newCachedOutreachNoticeStore(_ inner: MemoryOutreachNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachNoticeStore {
        return CachedOutreachNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach notices. Empty fields match all.
    final class OutreachNoticeQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachNotice) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [OutreachNotice]) -> [OutreachNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachNotices(_ store: any OutreachNoticeStore, query: OutreachNoticeQuery) -> [OutreachNotice] {
        return query.apply(store.list())
    }
}
