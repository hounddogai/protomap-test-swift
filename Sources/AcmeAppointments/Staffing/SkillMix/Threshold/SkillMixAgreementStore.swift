import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix agreements by code.
    protocol SkillMixAgreementStore {
        func find(_ code: String) -> SkillMixAgreement?
        func save(_ item: SkillMixAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixAgreementStore: SkillMixAgreementStore {
        var items: [String: SkillMixAgreement]
        var order: [String]

        init(items: [String: SkillMixAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixAgreement) {
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

        func list() -> [SkillMixAgreement] {
            var out: [SkillMixAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixAgreementStore() -> any SkillMixAgreementStore {
        return MemorySkillMixAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixAgreementStore: SkillMixAgreementStore {
        var inner: MemorySkillMixAgreementStore
        var cache: TTLCache<SkillMixAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixAgreementStore, cache: TTLCache<SkillMixAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixAgreement? {
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

        func save(_ item: SkillMixAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixAgreement] {
            return inner.list()
        }
    }

    static func newCachedSkillMixAgreementStore(_ inner: MemorySkillMixAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixAgreementStore {
        return CachedSkillMixAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix agreements. Empty fields match all.
    final class SkillMixAgreementQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixAgreement]) -> [SkillMixAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixAgreements(_ store: any SkillMixAgreementStore, query: SkillMixAgreementQuery) -> [SkillMixAgreement] {
        return query.apply(store.list())
    }
}
