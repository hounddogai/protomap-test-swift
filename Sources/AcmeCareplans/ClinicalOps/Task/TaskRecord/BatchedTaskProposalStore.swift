import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched task proposals by code.
    protocol BatchedTaskProposalStore {
        func find(_ code: String) -> BatchedTaskProposal?
        func save(_ item: BatchedTaskProposal)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedTaskProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedTaskProposalStore: BatchedTaskProposalStore {
        var items: [String: BatchedTaskProposal]
        var order: [String]

        init(items: [String: BatchedTaskProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedTaskProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedTaskProposal) {
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

        func list() -> [BatchedTaskProposal] {
            var out: [BatchedTaskProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedTaskProposalStore() -> any BatchedTaskProposalStore {
        return MemoryBatchedTaskProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedTaskProposalStore: BatchedTaskProposalStore {
        var inner: MemoryBatchedTaskProposalStore
        var cache: TTLCache<BatchedTaskProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedTaskProposalStore, cache: TTLCache<BatchedTaskProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedTaskProposal? {
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

        func save(_ item: BatchedTaskProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedTaskProposal] {
            return inner.list()
        }
    }

    static func newCachedBatchedTaskProposalStore(_ inner: MemoryBatchedTaskProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedTaskProposalStore {
        return CachedBatchedTaskProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched task proposals. Empty fields match all.
    final class BatchedTaskProposalQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedTaskProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedTaskProposal]) -> [BatchedTaskProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedTaskProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedTaskProposals(_ store: any BatchedTaskProposalStore, query: BatchedTaskProposalQuery) -> [BatchedTaskProposal] {
        return query.apply(store.list())
    }
}
