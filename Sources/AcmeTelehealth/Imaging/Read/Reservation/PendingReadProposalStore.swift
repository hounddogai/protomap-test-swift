import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending read proposals by code.
    protocol PendingReadProposalStore {
        func find(_ code: String) -> PendingReadProposal?
        func save(_ item: PendingReadProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReadProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReadProposalStore: PendingReadProposalStore {
        var items: [String: PendingReadProposal]
        var order: [String]

        init(items: [String: PendingReadProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReadProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReadProposal) {
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

        func list() -> [PendingReadProposal] {
            var out: [PendingReadProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReadProposalStore() -> any PendingReadProposalStore {
        return MemoryPendingReadProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReadProposalStore: PendingReadProposalStore {
        var inner: MemoryPendingReadProposalStore
        var cache: TTLCache<PendingReadProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReadProposalStore, cache: TTLCache<PendingReadProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReadProposal? {
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

        func save(_ item: PendingReadProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReadProposal] {
            return inner.list()
        }
    }

    static func newCachedPendingReadProposalStore(_ inner: MemoryPendingReadProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReadProposalStore {
        return CachedPendingReadProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending read proposals. Empty fields match all.
    final class PendingReadProposalQuery {
        var locale: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingReadProposal) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [PendingReadProposal]) -> [PendingReadProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReadProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReadProposals(_ store: any PendingReadProposalStore, query: PendingReadProposalQuery) -> [PendingReadProposal] {
        return query.apply(store.list())
    }
}
