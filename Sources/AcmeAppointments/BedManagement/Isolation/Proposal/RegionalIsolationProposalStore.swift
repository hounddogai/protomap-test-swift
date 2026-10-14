import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional isolation proposals by code.
    protocol RegionalIsolationProposalStore {
        func find(_ code: String) -> RegionalIsolationProposal?
        func save(_ item: RegionalIsolationProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalIsolationProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalIsolationProposalStore: RegionalIsolationProposalStore {
        var items: [String: RegionalIsolationProposal]
        var order: [String]

        init(items: [String: RegionalIsolationProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalIsolationProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalIsolationProposal) {
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

        func list() -> [RegionalIsolationProposal] {
            var out: [RegionalIsolationProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalIsolationProposalStore() -> any RegionalIsolationProposalStore {
        return MemoryRegionalIsolationProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalIsolationProposalStore: RegionalIsolationProposalStore {
        var inner: MemoryRegionalIsolationProposalStore
        var cache: TTLCache<RegionalIsolationProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalIsolationProposalStore, cache: TTLCache<RegionalIsolationProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalIsolationProposal? {
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

        func save(_ item: RegionalIsolationProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalIsolationProposal] {
            return inner.list()
        }
    }

    static func newCachedRegionalIsolationProposalStore(_ inner: MemoryRegionalIsolationProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalIsolationProposalStore {
        return CachedRegionalIsolationProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional isolation proposals. Empty fields match all.
    final class RegionalIsolationProposalQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalIsolationProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalIsolationProposal]) -> [RegionalIsolationProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalIsolationProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalIsolationProposals(_ store: any RegionalIsolationProposalStore, query: RegionalIsolationProposalQuery) -> [RegionalIsolationProposal] {
        return query.apply(store.list())
    }
}
