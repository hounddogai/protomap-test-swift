import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary substitution notices by code.
    protocol PrimarySubstitutionNoticeStore {
        func find(_ code: String) -> PrimarySubstitutionNotice?
        func save(_ item: PrimarySubstitutionNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySubstitutionNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySubstitutionNoticeStore: PrimarySubstitutionNoticeStore {
        var items: [String: PrimarySubstitutionNotice]
        var order: [String]

        init(items: [String: PrimarySubstitutionNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySubstitutionNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySubstitutionNotice) {
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

        func list() -> [PrimarySubstitutionNotice] {
            var out: [PrimarySubstitutionNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySubstitutionNoticeStore() -> any PrimarySubstitutionNoticeStore {
        return MemoryPrimarySubstitutionNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySubstitutionNoticeStore: PrimarySubstitutionNoticeStore {
        var inner: MemoryPrimarySubstitutionNoticeStore
        var cache: TTLCache<PrimarySubstitutionNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySubstitutionNoticeStore, cache: TTLCache<PrimarySubstitutionNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySubstitutionNotice? {
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

        func save(_ item: PrimarySubstitutionNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySubstitutionNotice] {
            return inner.list()
        }
    }

    static func newCachedPrimarySubstitutionNoticeStore(_ inner: MemoryPrimarySubstitutionNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySubstitutionNoticeStore {
        return CachedPrimarySubstitutionNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary substitution notices. Empty fields match all.
    final class PrimarySubstitutionNoticeQuery {
        var region: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySubstitutionNotice) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySubstitutionNotice]) -> [PrimarySubstitutionNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySubstitutionNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySubstitutionNotices(_ store: any PrimarySubstitutionNoticeStore, query: PrimarySubstitutionNoticeQuery) -> [PrimarySubstitutionNotice] {
        return query.apply(store.list())
    }
}
