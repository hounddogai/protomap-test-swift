import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment proposals by code.
    protocol AssessmentProposalStore {
        func find(_ code: String) -> AssessmentProposal?
        func save(_ item: AssessmentProposal)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentProposalStore: AssessmentProposalStore {
        var items: [String: AssessmentProposal]
        var order: [String]

        init(items: [String: AssessmentProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentProposal) {
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

        func list() -> [AssessmentProposal] {
            var out: [AssessmentProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentProposalStore() -> any AssessmentProposalStore {
        return MemoryAssessmentProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentProposalStore: AssessmentProposalStore {
        var inner: MemoryAssessmentProposalStore
        var cache: TTLCache<AssessmentProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentProposalStore, cache: TTLCache<AssessmentProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentProposal? {
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

        func save(_ item: AssessmentProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentProposal] {
            return inner.list()
        }
    }

    static func newCachedAssessmentProposalStore(_ inner: MemoryAssessmentProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentProposalStore {
        return CachedAssessmentProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment proposals. Empty fields match all.
    final class AssessmentProposalQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentProposal]) -> [AssessmentProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentProposals(_ store: any AssessmentProposalStore, query: AssessmentProposalQuery) -> [AssessmentProposal] {
        return query.apply(store.list())
    }
}
