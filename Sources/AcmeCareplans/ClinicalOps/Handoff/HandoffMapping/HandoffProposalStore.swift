import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff proposals by code.
    protocol HandoffProposalStore {
        func find(_ code: String) -> HandoffProposal?
        func save(_ item: HandoffProposal)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffProposalStore: HandoffProposalStore {
        var items: [String: HandoffProposal]
        var order: [String]

        init(items: [String: HandoffProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffProposal) {
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

        func list() -> [HandoffProposal] {
            var out: [HandoffProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffProposalStore() -> any HandoffProposalStore {
        return MemoryHandoffProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffProposalStore: HandoffProposalStore {
        var inner: MemoryHandoffProposalStore
        var cache: TTLCache<HandoffProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffProposalStore, cache: TTLCache<HandoffProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffProposal? {
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

        func save(_ item: HandoffProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffProposal] {
            return inner.list()
        }
    }

    static func newCachedHandoffProposalStore(_ inner: MemoryHandoffProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffProposalStore {
        return CachedHandoffProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff proposals. Empty fields match all.
    final class HandoffProposalQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffProposal]) -> [HandoffProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffProposals(_ store: any HandoffProposalStore, query: HandoffProposalQuery) -> [HandoffProposal] {
        return query.apply(store.list())
    }
}
