import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary census proposals by code.
    protocol PrimaryCensusProposalStore {
        func find(_ code: String) -> PrimaryCensusProposal?
        func save(_ item: PrimaryCensusProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCensusProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCensusProposalStore: PrimaryCensusProposalStore {
        var items: [String: PrimaryCensusProposal]
        var order: [String]

        init(items: [String: PrimaryCensusProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCensusProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCensusProposal) {
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

        func list() -> [PrimaryCensusProposal] {
            var out: [PrimaryCensusProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCensusProposalStore() -> any PrimaryCensusProposalStore {
        return MemoryPrimaryCensusProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCensusProposalStore: PrimaryCensusProposalStore {
        var inner: MemoryPrimaryCensusProposalStore
        var cache: TTLCache<PrimaryCensusProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCensusProposalStore, cache: TTLCache<PrimaryCensusProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCensusProposal? {
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

        func save(_ item: PrimaryCensusProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCensusProposal] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCensusProposalStore(_ inner: MemoryPrimaryCensusProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCensusProposalStore {
        return CachedPrimaryCensusProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary census proposals. Empty fields match all.
    final class PrimaryCensusProposalQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCensusProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCensusProposal]) -> [PrimaryCensusProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCensusProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCensusProposals(_ store: any PrimaryCensusProposalStore, query: PrimaryCensusProposalQuery) -> [PrimaryCensusProposal] {
        return query.apply(store.list())
    }
}
