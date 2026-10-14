import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime proposals by code.
    protocol OvertimeProposalStore {
        func find(_ code: String) -> OvertimeProposal?
        func save(_ item: OvertimeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeProposalStore: OvertimeProposalStore {
        var items: [String: OvertimeProposal]
        var order: [String]

        init(items: [String: OvertimeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeProposal) {
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

        func list() -> [OvertimeProposal] {
            var out: [OvertimeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeProposalStore() -> any OvertimeProposalStore {
        return MemoryOvertimeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeProposalStore: OvertimeProposalStore {
        var inner: MemoryOvertimeProposalStore
        var cache: TTLCache<OvertimeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeProposalStore, cache: TTLCache<OvertimeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeProposal? {
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

        func save(_ item: OvertimeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeProposal] {
            return inner.list()
        }
    }

    static func newCachedOvertimeProposalStore(_ inner: MemoryOvertimeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeProposalStore {
        return CachedOvertimeProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime proposals. Empty fields match all.
    final class OvertimeProposalQuery {
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

        func matches(_ item: OvertimeProposal) -> Bool {
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

        func apply(_ items: [OvertimeProposal]) -> [OvertimeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeProposals(_ store: any OvertimeProposalStore, query: OvertimeProposalQuery) -> [OvertimeProposal] {
        return query.apply(store.list())
    }
}
