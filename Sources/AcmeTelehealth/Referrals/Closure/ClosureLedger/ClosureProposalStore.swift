import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure proposals by code.
    protocol ClosureProposalStore {
        func find(_ code: String) -> ClosureProposal?
        func save(_ item: ClosureProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureProposalStore: ClosureProposalStore {
        var items: [String: ClosureProposal]
        var order: [String]

        init(items: [String: ClosureProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureProposal) {
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

        func list() -> [ClosureProposal] {
            var out: [ClosureProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureProposalStore() -> any ClosureProposalStore {
        return MemoryClosureProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureProposalStore: ClosureProposalStore {
        var inner: MemoryClosureProposalStore
        var cache: TTLCache<ClosureProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureProposalStore, cache: TTLCache<ClosureProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureProposal? {
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

        func save(_ item: ClosureProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureProposal] {
            return inner.list()
        }
    }

    static func newCachedClosureProposalStore(_ inner: MemoryClosureProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureProposalStore {
        return CachedClosureProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure proposals. Empty fields match all.
    final class ClosureProposalQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureProposal]) -> [ClosureProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureProposals(_ store: any ClosureProposalStore, query: ClosureProposalQuery) -> [ClosureProposal] {
        return query.apply(store.list())
    }
}
