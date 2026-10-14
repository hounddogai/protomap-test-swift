import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient outreach proposals by code.
    protocol LenientOutreachProposalStore {
        func find(_ code: String) -> LenientOutreachProposal?
        func save(_ item: LenientOutreachProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOutreachProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOutreachProposalStore: LenientOutreachProposalStore {
        var items: [String: LenientOutreachProposal]
        var order: [String]

        init(items: [String: LenientOutreachProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOutreachProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOutreachProposal) {
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

        func list() -> [LenientOutreachProposal] {
            var out: [LenientOutreachProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOutreachProposalStore() -> any LenientOutreachProposalStore {
        return MemoryLenientOutreachProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOutreachProposalStore: LenientOutreachProposalStore {
        var inner: MemoryLenientOutreachProposalStore
        var cache: TTLCache<LenientOutreachProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOutreachProposalStore, cache: TTLCache<LenientOutreachProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOutreachProposal? {
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

        func save(_ item: LenientOutreachProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOutreachProposal] {
            return inner.list()
        }
    }

    static func newCachedLenientOutreachProposalStore(_ inner: MemoryLenientOutreachProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOutreachProposalStore {
        return CachedLenientOutreachProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient outreach proposals. Empty fields match all.
    final class LenientOutreachProposalQuery {
        var unit: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRevision: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOutreachProposal) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientOutreachProposal]) -> [LenientOutreachProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOutreachProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOutreachProposals(_ store: any LenientOutreachProposalStore, query: LenientOutreachProposalQuery) -> [LenientOutreachProposal] {
        return query.apply(store.list())
    }
}
