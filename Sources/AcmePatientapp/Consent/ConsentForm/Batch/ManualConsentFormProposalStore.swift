import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual consent form proposals by code.
    protocol ManualConsentFormProposalStore {
        func find(_ code: String) -> ManualConsentFormProposal?
        func save(_ item: ManualConsentFormProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ManualConsentFormProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualConsentFormProposalStore: ManualConsentFormProposalStore {
        var items: [String: ManualConsentFormProposal]
        var order: [String]

        init(items: [String: ManualConsentFormProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualConsentFormProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualConsentFormProposal) {
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

        func list() -> [ManualConsentFormProposal] {
            var out: [ManualConsentFormProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualConsentFormProposalStore() -> any ManualConsentFormProposalStore {
        return MemoryManualConsentFormProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualConsentFormProposalStore: ManualConsentFormProposalStore {
        var inner: MemoryManualConsentFormProposalStore
        var cache: TTLCache<ManualConsentFormProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualConsentFormProposalStore, cache: TTLCache<ManualConsentFormProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualConsentFormProposal? {
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

        func save(_ item: ManualConsentFormProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualConsentFormProposal] {
            return inner.list()
        }
    }

    static func newCachedManualConsentFormProposalStore(_ inner: MemoryManualConsentFormProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualConsentFormProposalStore {
        return CachedManualConsentFormProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual consent form proposals. Empty fields match all.
    final class ManualConsentFormProposalQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualConsentFormProposal) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualConsentFormProposal]) -> [ManualConsentFormProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualConsentFormProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualConsentFormProposals(_ store: any ManualConsentFormProposalStore, query: ManualConsentFormProposalQuery) -> [ManualConsentFormProposal] {
        return query.apply(store.list())
    }
}
