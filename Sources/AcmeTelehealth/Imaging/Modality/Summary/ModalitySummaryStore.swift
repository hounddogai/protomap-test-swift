import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality summaries by code.
    protocol ModalitySummaryStore {
        func find(_ code: String) -> ModalitySummary?
        func save(_ item: ModalitySummary)
        func remove(_ code: String) -> Bool
        func list() -> [ModalitySummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalitySummaryStore: ModalitySummaryStore {
        var items: [String: ModalitySummary]
        var order: [String]

        init(items: [String: ModalitySummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalitySummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalitySummary) {
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

        func list() -> [ModalitySummary] {
            var out: [ModalitySummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalitySummaryStore() -> any ModalitySummaryStore {
        return MemoryModalitySummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalitySummaryStore: ModalitySummaryStore {
        var inner: MemoryModalitySummaryStore
        var cache: TTLCache<ModalitySummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalitySummaryStore, cache: TTLCache<ModalitySummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalitySummary? {
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

        func save(_ item: ModalitySummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalitySummary] {
            return inner.list()
        }
    }

    static func newCachedModalitySummaryStore(_ inner: MemoryModalitySummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalitySummaryStore {
        return CachedModalitySummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality summaries. Empty fields match all.
    final class ModalitySummaryQuery {
        var unit: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRefills: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalitySummary) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalitySummary]) -> [ModalitySummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalitySummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalitySummaries(_ store: any ModalitySummaryStore, query: ModalitySummaryQuery) -> [ModalitySummary] {
        return query.apply(store.list())
    }
}
