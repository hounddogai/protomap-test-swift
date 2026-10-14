import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps lenient task proposals by code.
    protocol LenientTaskProposalStore {
        func find(_ code: String) -> LenientTaskProposal?
        func save(_ item: LenientTaskProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LenientTaskProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientTaskProposalStore: LenientTaskProposalStore {
        var items: [String: LenientTaskProposal]
        var order: [String]

        init(items: [String: LenientTaskProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientTaskProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientTaskProposal) {
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

        func list() -> [LenientTaskProposal] {
            var out: [LenientTaskProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientTaskProposalStore() -> any LenientTaskProposalStore {
        return MemoryLenientTaskProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientTaskProposalStore: LenientTaskProposalStore {
        var inner: MemoryLenientTaskProposalStore
        var cache: TTLCache<LenientTaskProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientTaskProposalStore, cache: TTLCache<LenientTaskProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientTaskProposal? {
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

        func save(_ item: LenientTaskProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientTaskProposal] {
            return inner.list()
        }
    }

    static func newCachedLenientTaskProposalStore(_ inner: MemoryLenientTaskProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientTaskProposalStore {
        return CachedLenientTaskProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient task proposals. Empty fields match all.
    final class LenientTaskProposalQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientTaskProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientTaskProposal]) -> [LenientTaskProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientTaskProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientTaskProposals(_ store: any LenientTaskProposalStore, query: LenientTaskProposalQuery) -> [LenientTaskProposal] {
        return query.apply(store.list())
    }
}
