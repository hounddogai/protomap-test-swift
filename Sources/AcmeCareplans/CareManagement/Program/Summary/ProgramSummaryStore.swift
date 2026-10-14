import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program summaries by code.
    protocol ProgramSummaryStore {
        func find(_ code: String) -> ProgramSummary?
        func save(_ item: ProgramSummary)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramSummaryStore: ProgramSummaryStore {
        var items: [String: ProgramSummary]
        var order: [String]

        init(items: [String: ProgramSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramSummary) {
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

        func list() -> [ProgramSummary] {
            var out: [ProgramSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramSummaryStore() -> any ProgramSummaryStore {
        return MemoryProgramSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramSummaryStore: ProgramSummaryStore {
        var inner: MemoryProgramSummaryStore
        var cache: TTLCache<ProgramSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramSummaryStore, cache: TTLCache<ProgramSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramSummary? {
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

        func save(_ item: ProgramSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramSummary] {
            return inner.list()
        }
    }

    static func newCachedProgramSummaryStore(_ inner: MemoryProgramSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramSummaryStore {
        return CachedProgramSummaryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program summaries. Empty fields match all.
    final class ProgramSummaryQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramSummary) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramSummary]) -> [ProgramSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramSummaries(_ store: any ProgramSummaryStore, query: ProgramSummaryQuery) -> [ProgramSummary] {
        return query.apply(store.list())
    }
}
