import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending task proposals by code.
    protocol PendingTaskProposalStore {
        func find(_ code: String) -> PendingTaskProposal?
        func save(_ item: PendingTaskProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PendingTaskProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingTaskProposalStore: PendingTaskProposalStore {
        var items: [String: PendingTaskProposal]
        var order: [String]

        init(items: [String: PendingTaskProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingTaskProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingTaskProposal) {
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

        func list() -> [PendingTaskProposal] {
            var out: [PendingTaskProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingTaskProposalStore() -> any PendingTaskProposalStore {
        return MemoryPendingTaskProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingTaskProposalStore: PendingTaskProposalStore {
        var inner: MemoryPendingTaskProposalStore
        var cache: TTLCache<PendingTaskProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingTaskProposalStore, cache: TTLCache<PendingTaskProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingTaskProposal? {
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

        func save(_ item: PendingTaskProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingTaskProposal] {
            return inner.list()
        }
    }

    static func newCachedPendingTaskProposalStore(_ inner: MemoryPendingTaskProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingTaskProposalStore {
        return CachedPendingTaskProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending task proposals. Empty fields match all.
    final class PendingTaskProposalQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingTaskProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingTaskProposal]) -> [PendingTaskProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingTaskProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingTaskProposals(_ store: any PendingTaskProposalStore, query: PendingTaskProposalQuery) -> [PendingTaskProposal] {
        return query.apply(store.list())
    }
}
