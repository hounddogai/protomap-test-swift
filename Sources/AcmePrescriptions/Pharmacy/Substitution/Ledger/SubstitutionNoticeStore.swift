import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution notices by code.
    protocol SubstitutionNoticeStore {
        func find(_ code: String) -> SubstitutionNotice?
        func save(_ item: SubstitutionNotice)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionNoticeStore: SubstitutionNoticeStore {
        var items: [String: SubstitutionNotice]
        var order: [String]

        init(items: [String: SubstitutionNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionNotice) {
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

        func list() -> [SubstitutionNotice] {
            var out: [SubstitutionNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionNoticeStore() -> any SubstitutionNoticeStore {
        return MemorySubstitutionNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionNoticeStore: SubstitutionNoticeStore {
        var inner: MemorySubstitutionNoticeStore
        var cache: TTLCache<SubstitutionNotice>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionNoticeStore, cache: TTLCache<SubstitutionNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionNotice? {
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

        func save(_ item: SubstitutionNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionNotice] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionNoticeStore(_ inner: MemorySubstitutionNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionNoticeStore {
        return CachedSubstitutionNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution notices. Empty fields match all.
    final class SubstitutionNoticeQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionNotice) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionNotice]) -> [SubstitutionNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionNotices(_ store: any SubstitutionNoticeStore, query: SubstitutionNoticeQuery) -> [SubstitutionNotice] {
        return query.apply(store.list())
    }
}
