import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy result proposals by code.
    protocol LegacyResultProposalStore {
        func find(_ code: String) -> LegacyResultProposal?
        func save(_ item: LegacyResultProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyResultProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyResultProposalStore: LegacyResultProposalStore {
        var items: [String: LegacyResultProposal]
        var order: [String]

        init(items: [String: LegacyResultProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyResultProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyResultProposal) {
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

        func list() -> [LegacyResultProposal] {
            var out: [LegacyResultProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyResultProposalStore() -> any LegacyResultProposalStore {
        return MemoryLegacyResultProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyResultProposalStore: LegacyResultProposalStore {
        var inner: MemoryLegacyResultProposalStore
        var cache: TTLCache<LegacyResultProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyResultProposalStore, cache: TTLCache<LegacyResultProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyResultProposal? {
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

        func save(_ item: LegacyResultProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyResultProposal] {
            return inner.list()
        }
    }

    static func newCachedLegacyResultProposalStore(_ inner: MemoryLegacyResultProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyResultProposalStore {
        return CachedLegacyResultProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy result proposals. Empty fields match all.
    final class LegacyResultProposalQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyResultProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyResultProposal]) -> [LegacyResultProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyResultProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyResultProposals(_ store: any LegacyResultProposalStore, query: LegacyResultProposalQuery) -> [LegacyResultProposal] {
        return query.apply(store.list())
    }
}
