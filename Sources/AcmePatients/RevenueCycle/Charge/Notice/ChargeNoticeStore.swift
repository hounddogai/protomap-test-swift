import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge notices by code.
    protocol ChargeNoticeStore {
        func find(_ code: String) -> ChargeNotice?
        func save(_ item: ChargeNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeNoticeStore: ChargeNoticeStore {
        var items: [String: ChargeNotice]
        var order: [String]

        init(items: [String: ChargeNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeNotice) {
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

        func list() -> [ChargeNotice] {
            var out: [ChargeNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeNoticeStore() -> any ChargeNoticeStore {
        return MemoryChargeNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeNoticeStore: ChargeNoticeStore {
        var inner: MemoryChargeNoticeStore
        var cache: TTLCache<ChargeNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeNoticeStore, cache: TTLCache<ChargeNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeNotice? {
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

        func save(_ item: ChargeNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeNotice] {
            return inner.list()
        }
    }

    static func newCachedChargeNoticeStore(_ inner: MemoryChargeNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeNoticeStore {
        return CachedChargeNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge notices. Empty fields match all.
    final class ChargeNoticeQuery {
        var facility: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minWeight: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeNotice) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [ChargeNotice]) -> [ChargeNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeNotices(_ store: any ChargeNoticeStore, query: ChargeNoticeQuery) -> [ChargeNotice] {
        return query.apply(store.list())
    }
}
