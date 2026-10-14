import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary proposals by code.
    protocol FormularyProposalStore {
        func find(_ code: String) -> FormularyProposal?
        func save(_ item: FormularyProposal)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyProposalStore: FormularyProposalStore {
        var items: [String: FormularyProposal]
        var order: [String]

        init(items: [String: FormularyProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyProposal) {
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

        func list() -> [FormularyProposal] {
            var out: [FormularyProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyProposalStore() -> any FormularyProposalStore {
        return MemoryFormularyProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyProposalStore: FormularyProposalStore {
        var inner: MemoryFormularyProposalStore
        var cache: TTLCache<FormularyProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyProposalStore, cache: TTLCache<FormularyProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyProposal? {
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

        func save(_ item: FormularyProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyProposal] {
            return inner.list()
        }
    }

    static func newCachedFormularyProposalStore(_ inner: MemoryFormularyProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyProposalStore {
        return CachedFormularyProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary proposals. Empty fields match all.
    final class FormularyProposalQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [FormularyProposal]) -> [FormularyProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyProposals(_ store: any FormularyProposalStore, query: FormularyProposalQuery) -> [FormularyProposal] {
        return query.apply(store.list())
    }
}
