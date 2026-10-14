import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback accession notices by code.
    protocol FallbackAccessionNoticeStore {
        func find(_ code: String) -> FallbackAccessionNotice?
        func save(_ item: FallbackAccessionNotice)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAccessionNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAccessionNoticeStore: FallbackAccessionNoticeStore {
        var items: [String: FallbackAccessionNotice]
        var order: [String]

        init(items: [String: FallbackAccessionNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAccessionNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAccessionNotice) {
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

        func list() -> [FallbackAccessionNotice] {
            var out: [FallbackAccessionNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAccessionNoticeStore() -> any FallbackAccessionNoticeStore {
        return MemoryFallbackAccessionNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAccessionNoticeStore: FallbackAccessionNoticeStore {
        var inner: MemoryFallbackAccessionNoticeStore
        var cache: TTLCache<FallbackAccessionNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAccessionNoticeStore, cache: TTLCache<FallbackAccessionNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAccessionNotice? {
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

        func save(_ item: FallbackAccessionNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAccessionNotice] {
            return inner.list()
        }
    }

    static func newCachedFallbackAccessionNoticeStore(_ inner: MemoryFallbackAccessionNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAccessionNoticeStore {
        return CachedFallbackAccessionNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback accession notices. Empty fields match all.
    final class FallbackAccessionNoticeQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAccessionNotice) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackAccessionNotice]) -> [FallbackAccessionNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAccessionNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAccessionNotices(_ store: any FallbackAccessionNoticeStore, query: FallbackAccessionNoticeQuery) -> [FallbackAccessionNotice] {
        return query.apply(store.list())
    }
}
