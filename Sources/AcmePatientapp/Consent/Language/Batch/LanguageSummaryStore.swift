import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language summaries by code.
    protocol LanguageSummaryStore {
        func find(_ code: String) -> LanguageSummary?
        func save(_ item: LanguageSummary)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageSummaryStore: LanguageSummaryStore {
        var items: [String: LanguageSummary]
        var order: [String]

        init(items: [String: LanguageSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageSummary) {
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

        func list() -> [LanguageSummary] {
            var out: [LanguageSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageSummaryStore() -> any LanguageSummaryStore {
        return MemoryLanguageSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageSummaryStore: LanguageSummaryStore {
        var inner: MemoryLanguageSummaryStore
        var cache: TTLCache<LanguageSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageSummaryStore, cache: TTLCache<LanguageSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageSummary? {
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

        func save(_ item: LanguageSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageSummary] {
            return inner.list()
        }
    }

    static func newCachedLanguageSummaryStore(_ inner: MemoryLanguageSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageSummaryStore {
        return CachedLanguageSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language summaries. Empty fields match all.
    final class LanguageSummaryQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageSummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [LanguageSummary]) -> [LanguageSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageSummaries(_ store: any LanguageSummaryStore, query: LanguageSummaryQuery) -> [LanguageSummary] {
        return query.apply(store.list())
    }
}
