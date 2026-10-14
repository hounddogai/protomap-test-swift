import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback discharge plan proposals by code.
    protocol FallbackDischargePlanProposalStore {
        func find(_ code: String) -> FallbackDischargePlanProposal?
        func save(_ item: FallbackDischargePlanProposal)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDischargePlanProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDischargePlanProposalStore: FallbackDischargePlanProposalStore {
        var items: [String: FallbackDischargePlanProposal]
        var order: [String]

        init(items: [String: FallbackDischargePlanProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDischargePlanProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDischargePlanProposal) {
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

        func list() -> [FallbackDischargePlanProposal] {
            var out: [FallbackDischargePlanProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDischargePlanProposalStore() -> any FallbackDischargePlanProposalStore {
        return MemoryFallbackDischargePlanProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDischargePlanProposalStore: FallbackDischargePlanProposalStore {
        var inner: MemoryFallbackDischargePlanProposalStore
        var cache: TTLCache<FallbackDischargePlanProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDischargePlanProposalStore, cache: TTLCache<FallbackDischargePlanProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDischargePlanProposal? {
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

        func save(_ item: FallbackDischargePlanProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDischargePlanProposal] {
            return inner.list()
        }
    }

    static func newCachedFallbackDischargePlanProposalStore(_ inner: MemoryFallbackDischargePlanProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDischargePlanProposalStore {
        return CachedFallbackDischargePlanProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback discharge plan proposals. Empty fields match all.
    final class FallbackDischargePlanProposalQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDischargePlanProposal) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDischargePlanProposal]) -> [FallbackDischargePlanProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDischargePlanProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDischargePlanProposals(_ store: any FallbackDischargePlanProposalStore, query: FallbackDischargePlanProposalQuery) -> [FallbackDischargePlanProposal] {
        return query.apply(store.list())
    }
}
