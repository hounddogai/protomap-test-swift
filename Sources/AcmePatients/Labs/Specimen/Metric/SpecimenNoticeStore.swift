import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen notices by code.
    protocol SpecimenNoticeStore {
        func find(_ code: String) -> SpecimenNotice?
        func save(_ item: SpecimenNotice)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenNoticeStore: SpecimenNoticeStore {
        var items: [String: SpecimenNotice]
        var order: [String]

        init(items: [String: SpecimenNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenNotice) {
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

        func list() -> [SpecimenNotice] {
            var out: [SpecimenNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenNoticeStore() -> any SpecimenNoticeStore {
        return MemorySpecimenNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenNoticeStore: SpecimenNoticeStore {
        var inner: MemorySpecimenNoticeStore
        var cache: TTLCache<SpecimenNotice>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenNoticeStore, cache: TTLCache<SpecimenNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenNotice? {
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

        func save(_ item: SpecimenNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenNotice] {
            return inner.list()
        }
    }

    static func newCachedSpecimenNoticeStore(_ inner: MemorySpecimenNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenNoticeStore {
        return CachedSpecimenNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen notices. Empty fields match all.
    final class SpecimenNoticeQuery {
        var locale: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minRate: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenNotice) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenNotice]) -> [SpecimenNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenNotices(_ store: any SpecimenNoticeStore, query: SpecimenNoticeQuery) -> [SpecimenNotice] {
        return query.apply(store.list())
    }
}
