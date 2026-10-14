import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy summaries by code.
    protocol ProxySummaryStore {
        func find(_ code: String) -> ProxySummary?
        func save(_ item: ProxySummary)
        func remove(_ code: String) -> Bool
        func list() -> [ProxySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxySummaryStore: ProxySummaryStore {
        var items: [String: ProxySummary]
        var order: [String]

        init(items: [String: ProxySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxySummary) {
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

        func list() -> [ProxySummary] {
            var out: [ProxySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxySummaryStore() -> any ProxySummaryStore {
        return MemoryProxySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxySummaryStore: ProxySummaryStore {
        var inner: MemoryProxySummaryStore
        var cache: TTLCache<ProxySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxySummaryStore, cache: TTLCache<ProxySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxySummary? {
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

        func save(_ item: ProxySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxySummary] {
            return inner.list()
        }
    }

    static func newCachedProxySummaryStore(_ inner: MemoryProxySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxySummaryStore {
        return CachedProxySummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy summaries. Empty fields match all.
    final class ProxySummaryQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxySummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxySummary]) -> [ProxySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxySummaries(_ store: any ProxySummaryStore, query: ProxySummaryQuery) -> [ProxySummary] {
        return query.apply(store.list())
    }
}
