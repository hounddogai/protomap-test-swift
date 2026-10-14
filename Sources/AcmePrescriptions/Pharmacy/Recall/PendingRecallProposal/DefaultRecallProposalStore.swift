import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default recall proposals by code.
    protocol DefaultRecallProposalStore {
        func find(_ code: String) -> DefaultRecallProposal?
        func save(_ item: DefaultRecallProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRecallProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRecallProposalStore: DefaultRecallProposalStore {
        var items: [String: DefaultRecallProposal]
        var order: [String]

        init(items: [String: DefaultRecallProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRecallProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRecallProposal) {
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

        func list() -> [DefaultRecallProposal] {
            var out: [DefaultRecallProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRecallProposalStore() -> any DefaultRecallProposalStore {
        return MemoryDefaultRecallProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRecallProposalStore: DefaultRecallProposalStore {
        var inner: MemoryDefaultRecallProposalStore
        var cache: TTLCache<DefaultRecallProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRecallProposalStore, cache: TTLCache<DefaultRecallProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRecallProposal? {
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

        func save(_ item: DefaultRecallProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRecallProposal] {
            return inner.list()
        }
    }

    static func newCachedDefaultRecallProposalStore(_ inner: MemoryDefaultRecallProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRecallProposalStore {
        return CachedDefaultRecallProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default recall proposals. Empty fields match all.
    final class DefaultRecallProposalQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRecallProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [DefaultRecallProposal]) -> [DefaultRecallProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRecallProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRecallProposals(_ store: any DefaultRecallProposalStore, query: DefaultRecallProposalQuery) -> [DefaultRecallProposal] {
        return query.apply(store.list())
    }
}
