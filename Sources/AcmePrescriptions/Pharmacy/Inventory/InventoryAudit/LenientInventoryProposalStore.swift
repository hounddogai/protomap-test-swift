import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient inventory proposals by code.
    protocol LenientInventoryProposalStore {
        func find(_ code: String) -> LenientInventoryProposal?
        func save(_ item: LenientInventoryProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LenientInventoryProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientInventoryProposalStore: LenientInventoryProposalStore {
        var items: [String: LenientInventoryProposal]
        var order: [String]

        init(items: [String: LenientInventoryProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientInventoryProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientInventoryProposal) {
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

        func list() -> [LenientInventoryProposal] {
            var out: [LenientInventoryProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientInventoryProposalStore() -> any LenientInventoryProposalStore {
        return MemoryLenientInventoryProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientInventoryProposalStore: LenientInventoryProposalStore {
        var inner: MemoryLenientInventoryProposalStore
        var cache: TTLCache<LenientInventoryProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientInventoryProposalStore, cache: TTLCache<LenientInventoryProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientInventoryProposal? {
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

        func save(_ item: LenientInventoryProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientInventoryProposal] {
            return inner.list()
        }
    }

    static func newCachedLenientInventoryProposalStore(_ inner: MemoryLenientInventoryProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientInventoryProposalStore {
        return CachedLenientInventoryProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient inventory proposals. Empty fields match all.
    final class LenientInventoryProposalQuery {
        var source: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientInventoryProposal) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientInventoryProposal]) -> [LenientInventoryProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientInventoryProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientInventoryProposals(_ store: any LenientInventoryProposalStore, query: LenientInventoryProposalQuery) -> [LenientInventoryProposal] {
        return query.apply(store.list())
    }
}
