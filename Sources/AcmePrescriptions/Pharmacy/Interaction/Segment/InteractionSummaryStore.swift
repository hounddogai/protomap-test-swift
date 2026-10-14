import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction summaries by code.
    protocol InteractionSummaryStore {
        func find(_ code: String) -> InteractionSummary?
        func save(_ item: InteractionSummary)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionSummaryStore: InteractionSummaryStore {
        var items: [String: InteractionSummary]
        var order: [String]

        init(items: [String: InteractionSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionSummary) {
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

        func list() -> [InteractionSummary] {
            var out: [InteractionSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionSummaryStore() -> any InteractionSummaryStore {
        return MemoryInteractionSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionSummaryStore: InteractionSummaryStore {
        var inner: MemoryInteractionSummaryStore
        var cache: TTLCache<InteractionSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionSummaryStore, cache: TTLCache<InteractionSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionSummary? {
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

        func save(_ item: InteractionSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionSummary] {
            return inner.list()
        }
    }

    static func newCachedInteractionSummaryStore(_ inner: MemoryInteractionSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionSummaryStore {
        return CachedInteractionSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction summaries. Empty fields match all.
    final class InteractionSummaryQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionSummary]) -> [InteractionSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionSummaries(_ store: any InteractionSummaryStore, query: InteractionSummaryQuery) -> [InteractionSummary] {
        return query.apply(store.list())
    }
}
