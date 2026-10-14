import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form summaries by code.
    protocol ConsentFormSummaryStore {
        func find(_ code: String) -> ConsentFormSummary?
        func save(_ item: ConsentFormSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormSummaryStore: ConsentFormSummaryStore {
        var items: [String: ConsentFormSummary]
        var order: [String]

        init(items: [String: ConsentFormSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormSummary) {
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

        func list() -> [ConsentFormSummary] {
            var out: [ConsentFormSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormSummaryStore() -> any ConsentFormSummaryStore {
        return MemoryConsentFormSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormSummaryStore: ConsentFormSummaryStore {
        var inner: MemoryConsentFormSummaryStore
        var cache: TTLCache<ConsentFormSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormSummaryStore, cache: TTLCache<ConsentFormSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormSummary? {
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

        func save(_ item: ConsentFormSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormSummary] {
            return inner.list()
        }
    }

    static func newCachedConsentFormSummaryStore(_ inner: MemoryConsentFormSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormSummaryStore {
        return CachedConsentFormSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form summaries. Empty fields match all.
    final class ConsentFormSummaryQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ConsentFormSummary]) -> [ConsentFormSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormSummaries(_ store: any ConsentFormSummaryStore, query: ConsentFormSummaryQuery) -> [ConsentFormSummary] {
        return query.apply(store.list())
    }
}
