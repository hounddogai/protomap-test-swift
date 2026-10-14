import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance notices by code.
    protocol RemittanceNoticeStore {
        func find(_ code: String) -> RemittanceNotice?
        func save(_ item: RemittanceNotice)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceNoticeStore: RemittanceNoticeStore {
        var items: [String: RemittanceNotice]
        var order: [String]

        init(items: [String: RemittanceNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceNotice) {
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

        func list() -> [RemittanceNotice] {
            var out: [RemittanceNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceNoticeStore() -> any RemittanceNoticeStore {
        return MemoryRemittanceNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceNoticeStore: RemittanceNoticeStore {
        var inner: MemoryRemittanceNoticeStore
        var cache: TTLCache<RemittanceNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceNoticeStore, cache: TTLCache<RemittanceNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceNotice? {
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

        func save(_ item: RemittanceNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceNotice] {
            return inner.list()
        }
    }

    static func newCachedRemittanceNoticeStore(_ inner: MemoryRemittanceNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceNoticeStore {
        return CachedRemittanceNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance notices. Empty fields match all.
    final class RemittanceNoticeQuery {
        var facility: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCost: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceNotice) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [RemittanceNotice]) -> [RemittanceNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceNotices(_ store: any RemittanceNoticeStore, query: RemittanceNoticeQuery) -> [RemittanceNotice] {
        return query.apply(store.list())
    }
}
