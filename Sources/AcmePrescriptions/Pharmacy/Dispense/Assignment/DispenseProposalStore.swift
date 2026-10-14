import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense proposals by code.
    protocol DispenseProposalStore {
        func find(_ code: String) -> DispenseProposal?
        func save(_ item: DispenseProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseProposalStore: DispenseProposalStore {
        var items: [String: DispenseProposal]
        var order: [String]

        init(items: [String: DispenseProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseProposal) {
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

        func list() -> [DispenseProposal] {
            var out: [DispenseProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseProposalStore() -> any DispenseProposalStore {
        return MemoryDispenseProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseProposalStore: DispenseProposalStore {
        var inner: MemoryDispenseProposalStore
        var cache: TTLCache<DispenseProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseProposalStore, cache: TTLCache<DispenseProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseProposal? {
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

        func save(_ item: DispenseProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseProposal] {
            return inner.list()
        }
    }

    static func newCachedDispenseProposalStore(_ inner: MemoryDispenseProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseProposalStore {
        return CachedDispenseProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense proposals. Empty fields match all.
    final class DispenseProposalQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseProposal) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [DispenseProposal]) -> [DispenseProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseProposals(_ store: any DispenseProposalStore, query: DispenseProposalQuery) -> [DispenseProposal] {
        return query.apply(store.list())
    }
}
