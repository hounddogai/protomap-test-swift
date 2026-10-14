import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive dispense proposals by code.
    protocol AdaptiveDispenseProposalStore {
        func find(_ code: String) -> AdaptiveDispenseProposal?
        func save(_ item: AdaptiveDispenseProposal)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveDispenseProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveDispenseProposalStore: AdaptiveDispenseProposalStore {
        var items: [String: AdaptiveDispenseProposal]
        var order: [String]

        init(items: [String: AdaptiveDispenseProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveDispenseProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveDispenseProposal) {
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

        func list() -> [AdaptiveDispenseProposal] {
            var out: [AdaptiveDispenseProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveDispenseProposalStore() -> any AdaptiveDispenseProposalStore {
        return MemoryAdaptiveDispenseProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveDispenseProposalStore: AdaptiveDispenseProposalStore {
        var inner: MemoryAdaptiveDispenseProposalStore
        var cache: TTLCache<AdaptiveDispenseProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveDispenseProposalStore, cache: TTLCache<AdaptiveDispenseProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveDispenseProposal? {
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

        func save(_ item: AdaptiveDispenseProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveDispenseProposal] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveDispenseProposalStore(_ inner: MemoryAdaptiveDispenseProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveDispenseProposalStore {
        return CachedAdaptiveDispenseProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive dispense proposals. Empty fields match all.
    final class AdaptiveDispenseProposalQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveDispenseProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [AdaptiveDispenseProposal]) -> [AdaptiveDispenseProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveDispenseProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveDispenseProposals(_ store: any AdaptiveDispenseProposalStore, query: AdaptiveDispenseProposalQuery) -> [AdaptiveDispenseProposal] {
        return query.apply(store.list())
    }
}
