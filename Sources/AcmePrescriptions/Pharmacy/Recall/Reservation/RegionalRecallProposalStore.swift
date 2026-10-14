import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional recall proposals by code.
    protocol RegionalRecallProposalStore {
        func find(_ code: String) -> RegionalRecallProposal?
        func save(_ item: RegionalRecallProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRecallProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRecallProposalStore: RegionalRecallProposalStore {
        var items: [String: RegionalRecallProposal]
        var order: [String]

        init(items: [String: RegionalRecallProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRecallProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRecallProposal) {
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

        func list() -> [RegionalRecallProposal] {
            var out: [RegionalRecallProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRecallProposalStore() -> any RegionalRecallProposalStore {
        return MemoryRegionalRecallProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRecallProposalStore: RegionalRecallProposalStore {
        var inner: MemoryRegionalRecallProposalStore
        var cache: TTLCache<RegionalRecallProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRecallProposalStore, cache: TTLCache<RegionalRecallProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRecallProposal? {
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

        func save(_ item: RegionalRecallProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRecallProposal] {
            return inner.list()
        }
    }

    static func newCachedRegionalRecallProposalStore(_ inner: MemoryRegionalRecallProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRecallProposalStore {
        return CachedRegionalRecallProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional recall proposals. Empty fields match all.
    final class RegionalRecallProposalQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRecallProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRecallProposal]) -> [RegionalRecallProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRecallProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRecallProposals(_ store: any RegionalRecallProposalStore, query: RegionalRecallProposalQuery) -> [RegionalRecallProposal] {
        return query.apply(store.list())
    }
}
