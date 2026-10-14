import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form proposals by code.
    protocol ConsentFormProposalStore {
        func find(_ code: String) -> ConsentFormProposal?
        func save(_ item: ConsentFormProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormProposalStore: ConsentFormProposalStore {
        var items: [String: ConsentFormProposal]
        var order: [String]

        init(items: [String: ConsentFormProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormProposal) {
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

        func list() -> [ConsentFormProposal] {
            var out: [ConsentFormProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormProposalStore() -> any ConsentFormProposalStore {
        return MemoryConsentFormProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormProposalStore: ConsentFormProposalStore {
        var inner: MemoryConsentFormProposalStore
        var cache: TTLCache<ConsentFormProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormProposalStore, cache: TTLCache<ConsentFormProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormProposal? {
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

        func save(_ item: ConsentFormProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormProposal] {
            return inner.list()
        }
    }

    static func newCachedConsentFormProposalStore(_ inner: MemoryConsentFormProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormProposalStore {
        return CachedConsentFormProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form proposals. Empty fields match all.
    final class ConsentFormProposalQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormProposal]) -> [ConsentFormProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormProposals(_ store: any ConsentFormProposalStore, query: ConsentFormProposalQuery) -> [ConsentFormProposal] {
        return query.apply(store.list())
    }
}
