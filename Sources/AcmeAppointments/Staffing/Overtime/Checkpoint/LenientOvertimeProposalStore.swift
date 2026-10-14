import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient overtime proposals by code.
    protocol LenientOvertimeProposalStore {
        func find(_ code: String) -> LenientOvertimeProposal?
        func save(_ item: LenientOvertimeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOvertimeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOvertimeProposalStore: LenientOvertimeProposalStore {
        var items: [String: LenientOvertimeProposal]
        var order: [String]

        init(items: [String: LenientOvertimeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOvertimeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOvertimeProposal) {
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

        func list() -> [LenientOvertimeProposal] {
            var out: [LenientOvertimeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOvertimeProposalStore() -> any LenientOvertimeProposalStore {
        return MemoryLenientOvertimeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOvertimeProposalStore: LenientOvertimeProposalStore {
        var inner: MemoryLenientOvertimeProposalStore
        var cache: TTLCache<LenientOvertimeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOvertimeProposalStore, cache: TTLCache<LenientOvertimeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOvertimeProposal? {
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

        func save(_ item: LenientOvertimeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOvertimeProposal] {
            return inner.list()
        }
    }

    static func newCachedLenientOvertimeProposalStore(_ inner: MemoryLenientOvertimeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOvertimeProposalStore {
        return CachedLenientOvertimeProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient overtime proposals. Empty fields match all.
    final class LenientOvertimeProposalQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOvertimeProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientOvertimeProposal]) -> [LenientOvertimeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOvertimeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOvertimeProposals(_ store: any LenientOvertimeProposalStore, query: LenientOvertimeProposalQuery) -> [LenientOvertimeProposal] {
        return query.apply(store.list())
    }
}
