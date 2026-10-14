import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read proposals by code.
    protocol ReadProposalStore {
        func find(_ code: String) -> ReadProposal?
        func save(_ item: ReadProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ReadProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadProposalStore: ReadProposalStore {
        var items: [String: ReadProposal]
        var order: [String]

        init(items: [String: ReadProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadProposal) {
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

        func list() -> [ReadProposal] {
            var out: [ReadProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadProposalStore() -> any ReadProposalStore {
        return MemoryReadProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadProposalStore: ReadProposalStore {
        var inner: MemoryReadProposalStore
        var cache: TTLCache<ReadProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadProposalStore, cache: TTLCache<ReadProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadProposal? {
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

        func save(_ item: ReadProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadProposal] {
            return inner.list()
        }
    }

    static func newCachedReadProposalStore(_ inner: MemoryReadProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadProposalStore {
        return CachedReadProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read proposals. Empty fields match all.
    final class ReadProposalQuery {
        var ward: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadProposal) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ReadProposal]) -> [ReadProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadProposals(_ store: any ReadProposalStore, query: ReadProposalQuery) -> [ReadProposal] {
        return query.apply(store.list())
    }
}
