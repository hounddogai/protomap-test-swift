import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default courier proposals by code.
    protocol DefaultCourierProposalStore {
        func find(_ code: String) -> DefaultCourierProposal?
        func save(_ item: DefaultCourierProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCourierProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCourierProposalStore: DefaultCourierProposalStore {
        var items: [String: DefaultCourierProposal]
        var order: [String]

        init(items: [String: DefaultCourierProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCourierProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCourierProposal) {
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

        func list() -> [DefaultCourierProposal] {
            var out: [DefaultCourierProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCourierProposalStore() -> any DefaultCourierProposalStore {
        return MemoryDefaultCourierProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCourierProposalStore: DefaultCourierProposalStore {
        var inner: MemoryDefaultCourierProposalStore
        var cache: TTLCache<DefaultCourierProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCourierProposalStore, cache: TTLCache<DefaultCourierProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCourierProposal? {
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

        func save(_ item: DefaultCourierProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCourierProposal] {
            return inner.list()
        }
    }

    static func newCachedDefaultCourierProposalStore(_ inner: MemoryDefaultCourierProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCourierProposalStore {
        return CachedDefaultCourierProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default courier proposals. Empty fields match all.
    final class DefaultCourierProposalQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCourierProposal) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCourierProposal]) -> [DefaultCourierProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCourierProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCourierProposals(_ store: any DefaultCourierProposalStore, query: DefaultCourierProposalQuery) -> [DefaultCourierProposal] {
        return query.apply(store.list())
    }
}
