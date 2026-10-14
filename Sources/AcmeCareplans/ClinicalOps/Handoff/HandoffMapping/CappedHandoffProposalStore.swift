import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped handoff proposals by code.
    protocol CappedHandoffProposalStore {
        func find(_ code: String) -> CappedHandoffProposal?
        func save(_ item: CappedHandoffProposal)
        func remove(_ code: String) -> Bool
        func list() -> [CappedHandoffProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedHandoffProposalStore: CappedHandoffProposalStore {
        var items: [String: CappedHandoffProposal]
        var order: [String]

        init(items: [String: CappedHandoffProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedHandoffProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedHandoffProposal) {
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

        func list() -> [CappedHandoffProposal] {
            var out: [CappedHandoffProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedHandoffProposalStore() -> any CappedHandoffProposalStore {
        return MemoryCappedHandoffProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedHandoffProposalStore: CappedHandoffProposalStore {
        var inner: MemoryCappedHandoffProposalStore
        var cache: TTLCache<CappedHandoffProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedHandoffProposalStore, cache: TTLCache<CappedHandoffProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedHandoffProposal? {
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

        func save(_ item: CappedHandoffProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedHandoffProposal] {
            return inner.list()
        }
    }

    static func newCachedCappedHandoffProposalStore(_ inner: MemoryCappedHandoffProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedHandoffProposalStore {
        return CachedCappedHandoffProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped handoff proposals. Empty fields match all.
    final class CappedHandoffProposalQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedHandoffProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedHandoffProposal]) -> [CappedHandoffProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedHandoffProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedHandoffProposals(_ store: any CappedHandoffProposalStore, query: CappedHandoffProposalQuery) -> [CappedHandoffProposal] {
        return query.apply(store.list())
    }
}
