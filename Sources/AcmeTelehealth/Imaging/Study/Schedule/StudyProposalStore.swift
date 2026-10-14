import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study proposals by code.
    protocol StudyProposalStore {
        func find(_ code: String) -> StudyProposal?
        func save(_ item: StudyProposal)
        func remove(_ code: String) -> Bool
        func list() -> [StudyProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyProposalStore: StudyProposalStore {
        var items: [String: StudyProposal]
        var order: [String]

        init(items: [String: StudyProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyProposal) {
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

        func list() -> [StudyProposal] {
            var out: [StudyProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyProposalStore() -> any StudyProposalStore {
        return MemoryStudyProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyProposalStore: StudyProposalStore {
        var inner: MemoryStudyProposalStore
        var cache: TTLCache<StudyProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyProposalStore, cache: TTLCache<StudyProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyProposal? {
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

        func save(_ item: StudyProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyProposal] {
            return inner.list()
        }
    }

    static func newCachedStudyProposalStore(_ inner: MemoryStudyProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyProposalStore {
        return CachedStudyProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study proposals. Empty fields match all.
    final class StudyProposalQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyProposal]) -> [StudyProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyProposals(_ store: any StudyProposalStore, query: StudyProposalQuery) -> [StudyProposal] {
        return query.apply(store.list())
    }
}
