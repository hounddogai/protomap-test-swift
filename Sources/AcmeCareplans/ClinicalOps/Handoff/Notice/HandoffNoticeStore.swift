import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff notices by code.
    protocol HandoffNoticeStore {
        func find(_ code: String) -> HandoffNotice?
        func save(_ item: HandoffNotice)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffNoticeStore: HandoffNoticeStore {
        var items: [String: HandoffNotice]
        var order: [String]

        init(items: [String: HandoffNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffNotice) {
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

        func list() -> [HandoffNotice] {
            var out: [HandoffNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffNoticeStore() -> any HandoffNoticeStore {
        return MemoryHandoffNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffNoticeStore: HandoffNoticeStore {
        var inner: MemoryHandoffNoticeStore
        var cache: TTLCache<HandoffNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffNoticeStore, cache: TTLCache<HandoffNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffNotice? {
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

        func save(_ item: HandoffNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffNotice] {
            return inner.list()
        }
    }

    static func newCachedHandoffNoticeStore(_ inner: MemoryHandoffNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffNoticeStore {
        return CachedHandoffNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff notices. Empty fields match all.
    final class HandoffNoticeQuery {
        var locale: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRetries: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffNotice) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [HandoffNotice]) -> [HandoffNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffNotices(_ store: any HandoffNoticeStore, query: HandoffNoticeQuery) -> [HandoffNotice] {
        return query.apply(store.list())
    }
}
