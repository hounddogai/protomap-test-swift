import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual eligibility proposals by code.
    protocol ManualEligibilityProposalStore {
        func find(_ code: String) -> ManualEligibilityProposal?
        func save(_ item: ManualEligibilityProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ManualEligibilityProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualEligibilityProposalStore: ManualEligibilityProposalStore {
        var items: [String: ManualEligibilityProposal]
        var order: [String]

        init(items: [String: ManualEligibilityProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualEligibilityProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualEligibilityProposal) {
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

        func list() -> [ManualEligibilityProposal] {
            var out: [ManualEligibilityProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualEligibilityProposalStore() -> any ManualEligibilityProposalStore {
        return MemoryManualEligibilityProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualEligibilityProposalStore: ManualEligibilityProposalStore {
        var inner: MemoryManualEligibilityProposalStore
        var cache: TTLCache<ManualEligibilityProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualEligibilityProposalStore, cache: TTLCache<ManualEligibilityProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualEligibilityProposal? {
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

        func save(_ item: ManualEligibilityProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualEligibilityProposal] {
            return inner.list()
        }
    }

    static func newCachedManualEligibilityProposalStore(_ inner: MemoryManualEligibilityProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualEligibilityProposalStore {
        return CachedManualEligibilityProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual eligibility proposals. Empty fields match all.
    final class ManualEligibilityProposalQuery {
        var facility: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualEligibilityProposal) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualEligibilityProposal]) -> [ManualEligibilityProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualEligibilityProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualEligibilityProposals(_ store: any ManualEligibilityProposalStore, query: ManualEligibilityProposalQuery) -> [ManualEligibilityProposal] {
        return query.apply(store.list())
    }
}
