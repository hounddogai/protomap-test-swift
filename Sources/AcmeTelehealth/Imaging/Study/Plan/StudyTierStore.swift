import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study tiers by code.
    protocol StudyTierStore {
        func find(_ code: String) -> StudyTier?
        func save(_ item: StudyTier)
        func remove(_ code: String) -> Bool
        func list() -> [StudyTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyTierStore: StudyTierStore {
        var items: [String: StudyTier]
        var order: [String]

        init(items: [String: StudyTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyTier) {
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

        func list() -> [StudyTier] {
            var out: [StudyTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyTierStore() -> any StudyTierStore {
        return MemoryStudyTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyTierStore: StudyTierStore {
        var inner: MemoryStudyTierStore
        var cache: TTLCache<StudyTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyTierStore, cache: TTLCache<StudyTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyTier? {
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

        func save(_ item: StudyTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyTier] {
            return inner.list()
        }
    }

    static func newCachedStudyTierStore(_ inner: MemoryStudyTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyTierStore {
        return CachedStudyTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study tiers. Empty fields match all.
    final class StudyTierQuery {
        var facility: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyTier) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyTier]) -> [StudyTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyTiers(_ store: any StudyTierStore, query: StudyTierQuery) -> [StudyTier] {
        return query.apply(store.list())
    }
}
