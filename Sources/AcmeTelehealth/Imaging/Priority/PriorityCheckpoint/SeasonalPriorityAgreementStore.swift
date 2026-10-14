import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal priority agreements by code.
    protocol SeasonalPriorityAgreementStore {
        func find(_ code: String) -> SeasonalPriorityAgreement?
        func save(_ item: SeasonalPriorityAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalPriorityAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalPriorityAgreementStore: SeasonalPriorityAgreementStore {
        var items: [String: SeasonalPriorityAgreement]
        var order: [String]

        init(items: [String: SeasonalPriorityAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalPriorityAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalPriorityAgreement) {
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

        func list() -> [SeasonalPriorityAgreement] {
            var out: [SeasonalPriorityAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalPriorityAgreementStore() -> any SeasonalPriorityAgreementStore {
        return MemorySeasonalPriorityAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalPriorityAgreementStore: SeasonalPriorityAgreementStore {
        var inner: MemorySeasonalPriorityAgreementStore
        var cache: TTLCache<SeasonalPriorityAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalPriorityAgreementStore, cache: TTLCache<SeasonalPriorityAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalPriorityAgreement? {
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

        func save(_ item: SeasonalPriorityAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalPriorityAgreement] {
            return inner.list()
        }
    }

    static func newCachedSeasonalPriorityAgreementStore(_ inner: MemorySeasonalPriorityAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalPriorityAgreementStore {
        return CachedSeasonalPriorityAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal priority agreements. Empty fields match all.
    final class SeasonalPriorityAgreementQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalPriorityAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalPriorityAgreement]) -> [SeasonalPriorityAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalPriorityAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalPriorityAgreements(_ store: any SeasonalPriorityAgreementStore, query: SeasonalPriorityAgreementQuery) -> [SeasonalPriorityAgreement] {
        return query.apply(store.list())
    }
}
