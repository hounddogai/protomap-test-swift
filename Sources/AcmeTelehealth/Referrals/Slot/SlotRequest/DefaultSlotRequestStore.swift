import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default slot requests by code.
    protocol DefaultSlotRequestStore {
        func find(_ code: String) -> DefaultSlotRequest?
        func save(_ item: DefaultSlotRequest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSlotRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSlotRequestStore: DefaultSlotRequestStore {
        var items: [String: DefaultSlotRequest]
        var order: [String]

        init(items: [String: DefaultSlotRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSlotRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSlotRequest) {
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

        func list() -> [DefaultSlotRequest] {
            var out: [DefaultSlotRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSlotRequestStore() -> any DefaultSlotRequestStore {
        return MemoryDefaultSlotRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSlotRequestStore: DefaultSlotRequestStore {
        var inner: MemoryDefaultSlotRequestStore
        var cache: TTLCache<DefaultSlotRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSlotRequestStore, cache: TTLCache<DefaultSlotRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSlotRequest? {
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

        func save(_ item: DefaultSlotRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSlotRequest] {
            return inner.list()
        }
    }

    static func newCachedDefaultSlotRequestStore(_ inner: MemoryDefaultSlotRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSlotRequestStore {
        return CachedDefaultSlotRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default slot requests. Empty fields match all.
    final class DefaultSlotRequestQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSlotRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultSlotRequest]) -> [DefaultSlotRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSlotRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSlotRequests(_ store: any DefaultSlotRequestStore, query: DefaultSlotRequestQuery) -> [DefaultSlotRequest] {
        return query.apply(store.list())
    }
}
