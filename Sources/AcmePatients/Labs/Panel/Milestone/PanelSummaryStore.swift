import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel summaries by code.
    protocol PanelSummaryStore {
        func find(_ code: String) -> PanelSummary?
        func save(_ item: PanelSummary)
        func remove(_ code: String) -> Bool
        func list() -> [PanelSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelSummaryStore: PanelSummaryStore {
        var items: [String: PanelSummary]
        var order: [String]

        init(items: [String: PanelSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelSummary) {
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

        func list() -> [PanelSummary] {
            var out: [PanelSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelSummaryStore() -> any PanelSummaryStore {
        return MemoryPanelSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelSummaryStore: PanelSummaryStore {
        var inner: MemoryPanelSummaryStore
        var cache: TTLCache<PanelSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelSummaryStore, cache: TTLCache<PanelSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelSummary? {
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

        func save(_ item: PanelSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelSummary] {
            return inner.list()
        }
    }

    static func newCachedPanelSummaryStore(_ inner: MemoryPanelSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelSummaryStore {
        return CachedPanelSummaryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel summaries. Empty fields match all.
    final class PanelSummaryQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelSummary) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelSummary]) -> [PanelSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelSummaries(_ store: any PanelSummaryStore, query: PanelSummaryQuery) -> [PanelSummary] {
        return query.apply(store.list())
    }
}
