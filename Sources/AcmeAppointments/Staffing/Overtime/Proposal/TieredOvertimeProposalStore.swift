import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered overtime proposals by code.
    protocol TieredOvertimeProposalStore {
        func find(_ code: String) -> TieredOvertimeProposal?
        func save(_ item: TieredOvertimeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOvertimeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOvertimeProposalStore: TieredOvertimeProposalStore {
        var items: [String: TieredOvertimeProposal]
        var order: [String]

        init(items: [String: TieredOvertimeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOvertimeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOvertimeProposal) {
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

        func list() -> [TieredOvertimeProposal] {
            var out: [TieredOvertimeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOvertimeProposalStore() -> any TieredOvertimeProposalStore {
        return MemoryTieredOvertimeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOvertimeProposalStore: TieredOvertimeProposalStore {
        var inner: MemoryTieredOvertimeProposalStore
        var cache: TTLCache<TieredOvertimeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOvertimeProposalStore, cache: TTLCache<TieredOvertimeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOvertimeProposal? {
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

        func save(_ item: TieredOvertimeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOvertimeProposal] {
            return inner.list()
        }
    }

    static func newCachedTieredOvertimeProposalStore(_ inner: MemoryTieredOvertimeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOvertimeProposalStore {
        return CachedTieredOvertimeProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered overtime proposals. Empty fields match all.
    final class TieredOvertimeProposalQuery {
        var category: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOvertimeProposal) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredOvertimeProposal]) -> [TieredOvertimeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOvertimeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOvertimeProposals(_ store: any TieredOvertimeProposalStore, query: TieredOvertimeProposalQuery) -> [TieredOvertimeProposal] {
        return query.apply(store.list())
    }
}
