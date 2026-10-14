import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default interaction agreements by code.
    protocol DefaultInteractionAgreementStore {
        func find(_ code: String) -> DefaultInteractionAgreement?
        func save(_ item: DefaultInteractionAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultInteractionAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultInteractionAgreementStore: DefaultInteractionAgreementStore {
        var items: [String: DefaultInteractionAgreement]
        var order: [String]

        init(items: [String: DefaultInteractionAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultInteractionAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultInteractionAgreement) {
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

        func list() -> [DefaultInteractionAgreement] {
            var out: [DefaultInteractionAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultInteractionAgreementStore() -> any DefaultInteractionAgreementStore {
        return MemoryDefaultInteractionAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultInteractionAgreementStore: DefaultInteractionAgreementStore {
        var inner: MemoryDefaultInteractionAgreementStore
        var cache: TTLCache<DefaultInteractionAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultInteractionAgreementStore, cache: TTLCache<DefaultInteractionAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultInteractionAgreement? {
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

        func save(_ item: DefaultInteractionAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultInteractionAgreement] {
            return inner.list()
        }
    }

    static func newCachedDefaultInteractionAgreementStore(_ inner: MemoryDefaultInteractionAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultInteractionAgreementStore {
        return CachedDefaultInteractionAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default interaction agreements. Empty fields match all.
    final class DefaultInteractionAgreementQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultInteractionAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultInteractionAgreement]) -> [DefaultInteractionAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultInteractionAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultInteractionAgreements(_ store: any DefaultInteractionAgreementStore, query: DefaultInteractionAgreementQuery) -> [DefaultInteractionAgreement] {
        return query.apply(store.list())
    }
}
