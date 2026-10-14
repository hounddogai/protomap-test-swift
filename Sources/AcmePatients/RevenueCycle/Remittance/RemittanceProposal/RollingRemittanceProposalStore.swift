import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps rolling remittance proposals by code.
    protocol RollingRemittanceProposalStore {
        func find(_ code: String) -> RollingRemittanceProposal?
        func save(_ item: RollingRemittanceProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRemittanceProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRemittanceProposalStore: RollingRemittanceProposalStore {
        var items: [String: RollingRemittanceProposal]
        var order: [String]

        init(items: [String: RollingRemittanceProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRemittanceProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRemittanceProposal) {
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

        func list() -> [RollingRemittanceProposal] {
            var out: [RollingRemittanceProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRemittanceProposalStore() -> any RollingRemittanceProposalStore {
        return MemoryRollingRemittanceProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRemittanceProposalStore: RollingRemittanceProposalStore {
        var inner: MemoryRollingRemittanceProposalStore
        var cache: TTLCache<RollingRemittanceProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRemittanceProposalStore, cache: TTLCache<RollingRemittanceProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRemittanceProposal? {
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

        func save(_ item: RollingRemittanceProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRemittanceProposal] {
            return inner.list()
        }
    }

    static func newCachedRollingRemittanceProposalStore(_ inner: MemoryRollingRemittanceProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRemittanceProposalStore {
        return CachedRollingRemittanceProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling remittance proposals. Empty fields match all.
    final class RollingRemittanceProposalQuery {
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

        func matches(_ item: RollingRemittanceProposal) -> Bool {
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

        func apply(_ items: [RollingRemittanceProposal]) -> [RollingRemittanceProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRemittanceProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRemittanceProposals(_ store: any RollingRemittanceProposalStore, query: RollingRemittanceProposalQuery) -> [RollingRemittanceProposal] {
        return query.apply(store.list())
    }
}
