import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language notices by code.
    protocol LanguageNoticeStore {
        func find(_ code: String) -> LanguageNotice?
        func save(_ item: LanguageNotice)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageNoticeStore: LanguageNoticeStore {
        var items: [String: LanguageNotice]
        var order: [String]

        init(items: [String: LanguageNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageNotice) {
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

        func list() -> [LanguageNotice] {
            var out: [LanguageNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageNoticeStore() -> any LanguageNoticeStore {
        return MemoryLanguageNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageNoticeStore: LanguageNoticeStore {
        var inner: MemoryLanguageNoticeStore
        var cache: TTLCache<LanguageNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageNoticeStore, cache: TTLCache<LanguageNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageNotice? {
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

        func save(_ item: LanguageNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageNotice] {
            return inner.list()
        }
    }

    static func newCachedLanguageNoticeStore(_ inner: MemoryLanguageNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageNoticeStore {
        return CachedLanguageNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language notices. Empty fields match all.
    final class LanguageNoticeQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageNotice]) -> [LanguageNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageNotices(_ store: any LanguageNoticeStore, query: LanguageNoticeQuery) -> [LanguageNotice] {
        return query.apply(store.list())
    }
}
