import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction agreements by code.
    protocol InteractionAgreementStore {
        func find(_ code: String) -> InteractionAgreement?
        func save(_ item: InteractionAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionAgreementStore: InteractionAgreementStore {
        var items: [String: InteractionAgreement]
        var order: [String]

        init(items: [String: InteractionAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionAgreement) {
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

        func list() -> [InteractionAgreement] {
            var out: [InteractionAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionAgreementStore() -> any InteractionAgreementStore {
        return MemoryInteractionAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionAgreementStore: InteractionAgreementStore {
        var inner: MemoryInteractionAgreementStore
        var cache: TTLCache<InteractionAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionAgreementStore, cache: TTLCache<InteractionAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionAgreement? {
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

        func save(_ item: InteractionAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionAgreement] {
            return inner.list()
        }
    }

    static func newCachedInteractionAgreementStore(_ inner: MemoryInteractionAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionAgreementStore {
        return CachedInteractionAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction agreements. Empty fields match all.
    final class InteractionAgreementQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionAgreement]) -> [InteractionAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionAgreements(_ store: any InteractionAgreementStore, query: InteractionAgreementQuery) -> [InteractionAgreement] {
        return query.apply(store.list())
    }
}
