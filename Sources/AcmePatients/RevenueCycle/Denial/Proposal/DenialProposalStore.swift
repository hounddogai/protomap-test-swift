import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial proposals by code.
    protocol DenialProposalStore {
        func find(_ code: String) -> DenialProposal?
        func save(_ item: DenialProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DenialProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialProposalStore: DenialProposalStore {
        var items: [String: DenialProposal]
        var order: [String]

        init(items: [String: DenialProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialProposal) {
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

        func list() -> [DenialProposal] {
            var out: [DenialProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialProposalStore() -> any DenialProposalStore {
        return MemoryDenialProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialProposalStore: DenialProposalStore {
        var inner: MemoryDenialProposalStore
        var cache: TTLCache<DenialProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialProposalStore, cache: TTLCache<DenialProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialProposal? {
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

        func save(_ item: DenialProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialProposal] {
            return inner.list()
        }
    }

    static func newCachedDenialProposalStore(_ inner: MemoryDenialProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialProposalStore {
        return CachedDenialProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial proposals. Empty fields match all.
    final class DenialProposalQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialProposal]) -> [DenialProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialProposals(_ store: any DenialProposalStore, query: DenialProposalQuery) -> [DenialProposal] {
        return query.apply(store.list())
    }
}
