import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict rounding proposals by code.
    protocol StrictRoundingProposalStore {
        func find(_ code: String) -> StrictRoundingProposal?
        func save(_ item: StrictRoundingProposal)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRoundingProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRoundingProposalStore: StrictRoundingProposalStore {
        var items: [String: StrictRoundingProposal]
        var order: [String]

        init(items: [String: StrictRoundingProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRoundingProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRoundingProposal) {
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

        func list() -> [StrictRoundingProposal] {
            var out: [StrictRoundingProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRoundingProposalStore() -> any StrictRoundingProposalStore {
        return MemoryStrictRoundingProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRoundingProposalStore: StrictRoundingProposalStore {
        var inner: MemoryStrictRoundingProposalStore
        var cache: TTLCache<StrictRoundingProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRoundingProposalStore, cache: TTLCache<StrictRoundingProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRoundingProposal? {
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

        func save(_ item: StrictRoundingProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRoundingProposal] {
            return inner.list()
        }
    }

    static func newCachedStrictRoundingProposalStore(_ inner: MemoryStrictRoundingProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRoundingProposalStore {
        return CachedStrictRoundingProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict rounding proposals. Empty fields match all.
    final class StrictRoundingProposalQuery {
        var locale: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRoundingProposal) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRoundingProposal]) -> [StrictRoundingProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRoundingProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRoundingProposals(_ store: any StrictRoundingProposalStore, query: StrictRoundingProposalQuery) -> [StrictRoundingProposal] {
        return query.apply(store.list())
    }
}
