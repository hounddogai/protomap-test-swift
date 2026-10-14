import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback substitution proposals by code.
    protocol FallbackSubstitutionProposalStore {
        func find(_ code: String) -> FallbackSubstitutionProposal?
        func save(_ item: FallbackSubstitutionProposal)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSubstitutionProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSubstitutionProposalStore: FallbackSubstitutionProposalStore {
        var items: [String: FallbackSubstitutionProposal]
        var order: [String]

        init(items: [String: FallbackSubstitutionProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSubstitutionProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSubstitutionProposal) {
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

        func list() -> [FallbackSubstitutionProposal] {
            var out: [FallbackSubstitutionProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSubstitutionProposalStore() -> any FallbackSubstitutionProposalStore {
        return MemoryFallbackSubstitutionProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSubstitutionProposalStore: FallbackSubstitutionProposalStore {
        var inner: MemoryFallbackSubstitutionProposalStore
        var cache: TTLCache<FallbackSubstitutionProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSubstitutionProposalStore, cache: TTLCache<FallbackSubstitutionProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSubstitutionProposal? {
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

        func save(_ item: FallbackSubstitutionProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSubstitutionProposal] {
            return inner.list()
        }
    }

    static func newCachedFallbackSubstitutionProposalStore(_ inner: MemoryFallbackSubstitutionProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSubstitutionProposalStore {
        return CachedFallbackSubstitutionProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback substitution proposals. Empty fields match all.
    final class FallbackSubstitutionProposalQuery {
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

        func matches(_ item: FallbackSubstitutionProposal) -> Bool {
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

        func apply(_ items: [FallbackSubstitutionProposal]) -> [FallbackSubstitutionProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSubstitutionProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSubstitutionProposals(_ store: any FallbackSubstitutionProposalStore, query: FallbackSubstitutionProposalQuery) -> [FallbackSubstitutionProposal] {
        return query.apply(store.list())
    }
}
