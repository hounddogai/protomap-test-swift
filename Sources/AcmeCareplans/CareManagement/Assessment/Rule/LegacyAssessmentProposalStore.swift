import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy assessment proposals by code.
    protocol LegacyAssessmentProposalStore {
        func find(_ code: String) -> LegacyAssessmentProposal?
        func save(_ item: LegacyAssessmentProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAssessmentProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAssessmentProposalStore: LegacyAssessmentProposalStore {
        var items: [String: LegacyAssessmentProposal]
        var order: [String]

        init(items: [String: LegacyAssessmentProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAssessmentProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAssessmentProposal) {
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

        func list() -> [LegacyAssessmentProposal] {
            var out: [LegacyAssessmentProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAssessmentProposalStore() -> any LegacyAssessmentProposalStore {
        return MemoryLegacyAssessmentProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAssessmentProposalStore: LegacyAssessmentProposalStore {
        var inner: MemoryLegacyAssessmentProposalStore
        var cache: TTLCache<LegacyAssessmentProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAssessmentProposalStore, cache: TTLCache<LegacyAssessmentProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAssessmentProposal? {
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

        func save(_ item: LegacyAssessmentProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAssessmentProposal] {
            return inner.list()
        }
    }

    static func newCachedLegacyAssessmentProposalStore(_ inner: MemoryLegacyAssessmentProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAssessmentProposalStore {
        return CachedLegacyAssessmentProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy assessment proposals. Empty fields match all.
    final class LegacyAssessmentProposalQuery {
        var region: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAssessmentProposal) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAssessmentProposal]) -> [LegacyAssessmentProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAssessmentProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAssessmentProposals(_ store: any LegacyAssessmentProposalStore, query: LegacyAssessmentProposalQuery) -> [LegacyAssessmentProposal] {
        return query.apply(store.list())
    }
}
