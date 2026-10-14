import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy specimen notices by code.
    protocol LegacySpecimenNoticeStore {
        func find(_ code: String) -> LegacySpecimenNotice?
        func save(_ item: LegacySpecimenNotice)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySpecimenNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySpecimenNoticeStore: LegacySpecimenNoticeStore {
        var items: [String: LegacySpecimenNotice]
        var order: [String]

        init(items: [String: LegacySpecimenNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySpecimenNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySpecimenNotice) {
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

        func list() -> [LegacySpecimenNotice] {
            var out: [LegacySpecimenNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySpecimenNoticeStore() -> any LegacySpecimenNoticeStore {
        return MemoryLegacySpecimenNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySpecimenNoticeStore: LegacySpecimenNoticeStore {
        var inner: MemoryLegacySpecimenNoticeStore
        var cache: TTLCache<LegacySpecimenNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySpecimenNoticeStore, cache: TTLCache<LegacySpecimenNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySpecimenNotice? {
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

        func save(_ item: LegacySpecimenNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySpecimenNotice] {
            return inner.list()
        }
    }

    static func newCachedLegacySpecimenNoticeStore(_ inner: MemoryLegacySpecimenNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySpecimenNoticeStore {
        return CachedLegacySpecimenNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy specimen notices. Empty fields match all.
    final class LegacySpecimenNoticeQuery {
        var category: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minSequence: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySpecimenNotice) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacySpecimenNotice]) -> [LegacySpecimenNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySpecimenNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySpecimenNotices(_ store: any LegacySpecimenNoticeStore, query: LegacySpecimenNoticeQuery) -> [LegacySpecimenNotice] {
        return query.apply(store.list())
    }
}
