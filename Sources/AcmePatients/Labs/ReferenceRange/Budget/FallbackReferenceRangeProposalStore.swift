import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback reference range proposals by code.
    protocol FallbackReferenceRangeProposalStore {
        func find(_ code: String) -> FallbackReferenceRangeProposal?
        func save(_ item: FallbackReferenceRangeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackReferenceRangeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackReferenceRangeProposalStore: FallbackReferenceRangeProposalStore {
        var items: [String: FallbackReferenceRangeProposal]
        var order: [String]

        init(items: [String: FallbackReferenceRangeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackReferenceRangeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackReferenceRangeProposal) {
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

        func list() -> [FallbackReferenceRangeProposal] {
            var out: [FallbackReferenceRangeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackReferenceRangeProposalStore() -> any FallbackReferenceRangeProposalStore {
        return MemoryFallbackReferenceRangeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackReferenceRangeProposalStore: FallbackReferenceRangeProposalStore {
        var inner: MemoryFallbackReferenceRangeProposalStore
        var cache: TTLCache<FallbackReferenceRangeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackReferenceRangeProposalStore, cache: TTLCache<FallbackReferenceRangeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackReferenceRangeProposal? {
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

        func save(_ item: FallbackReferenceRangeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackReferenceRangeProposal] {
            return inner.list()
        }
    }

    static func newCachedFallbackReferenceRangeProposalStore(_ inner: MemoryFallbackReferenceRangeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackReferenceRangeProposalStore {
        return CachedFallbackReferenceRangeProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback reference range proposals. Empty fields match all.
    final class FallbackReferenceRangeProposalQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackReferenceRangeProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackReferenceRangeProposal]) -> [FallbackReferenceRangeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackReferenceRangeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackReferenceRangeProposals(_ store: any FallbackReferenceRangeProposalStore, query: FallbackReferenceRangeProposalQuery) -> [FallbackReferenceRangeProposal] {
        return query.apply(store.list())
    }
}
