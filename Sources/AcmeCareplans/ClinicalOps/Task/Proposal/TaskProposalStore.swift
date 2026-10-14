import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task proposals by code.
    protocol TaskProposalStore {
        func find(_ code: String) -> TaskProposal?
        func save(_ item: TaskProposal)
        func remove(_ code: String) -> Bool
        func list() -> [TaskProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskProposalStore: TaskProposalStore {
        var items: [String: TaskProposal]
        var order: [String]

        init(items: [String: TaskProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskProposal) {
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

        func list() -> [TaskProposal] {
            var out: [TaskProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskProposalStore() -> any TaskProposalStore {
        return MemoryTaskProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskProposalStore: TaskProposalStore {
        var inner: MemoryTaskProposalStore
        var cache: TTLCache<TaskProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskProposalStore, cache: TTLCache<TaskProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskProposal? {
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

        func save(_ item: TaskProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskProposal] {
            return inner.list()
        }
    }

    static func newCachedTaskProposalStore(_ inner: MemoryTaskProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskProposalStore {
        return CachedTaskProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task proposals. Empty fields match all.
    final class TaskProposalQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskProposal) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskProposal]) -> [TaskProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskProposals(_ store: any TaskProposalStore, query: TaskProposalQuery) -> [TaskProposal] {
        return query.apply(store.list())
    }
}
