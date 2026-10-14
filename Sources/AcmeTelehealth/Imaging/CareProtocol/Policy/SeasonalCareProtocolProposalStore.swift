import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal care protocol proposals by code.
    protocol SeasonalCareProtocolProposalStore {
        func find(_ code: String) -> SeasonalCareProtocolProposal?
        func save(_ item: SeasonalCareProtocolProposal)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareProtocolProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareProtocolProposalStore: SeasonalCareProtocolProposalStore {
        var items: [String: SeasonalCareProtocolProposal]
        var order: [String]

        init(items: [String: SeasonalCareProtocolProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareProtocolProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareProtocolProposal) {
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

        func list() -> [SeasonalCareProtocolProposal] {
            var out: [SeasonalCareProtocolProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareProtocolProposalStore() -> any SeasonalCareProtocolProposalStore {
        return MemorySeasonalCareProtocolProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareProtocolProposalStore: SeasonalCareProtocolProposalStore {
        var inner: MemorySeasonalCareProtocolProposalStore
        var cache: TTLCache<SeasonalCareProtocolProposal>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareProtocolProposalStore, cache: TTLCache<SeasonalCareProtocolProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareProtocolProposal? {
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

        func save(_ item: SeasonalCareProtocolProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareProtocolProposal] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareProtocolProposalStore(_ inner: MemorySeasonalCareProtocolProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareProtocolProposalStore {
        return CachedSeasonalCareProtocolProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care protocol proposals. Empty fields match all.
    final class SeasonalCareProtocolProposalQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareProtocolProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareProtocolProposal]) -> [SeasonalCareProtocolProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareProtocolProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareProtocolProposals(_ store: any SeasonalCareProtocolProposalStore, query: SeasonalCareProtocolProposalQuery) -> [SeasonalCareProtocolProposal] {
        return query.apply(store.list())
    }
}
