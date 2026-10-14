import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness notices by code.
    protocol WitnessNoticeStore {
        func find(_ code: String) -> WitnessNotice?
        func save(_ item: WitnessNotice)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessNoticeStore: WitnessNoticeStore {
        var items: [String: WitnessNotice]
        var order: [String]

        init(items: [String: WitnessNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessNotice) {
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

        func list() -> [WitnessNotice] {
            var out: [WitnessNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessNoticeStore() -> any WitnessNoticeStore {
        return MemoryWitnessNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessNoticeStore: WitnessNoticeStore {
        var inner: MemoryWitnessNoticeStore
        var cache: TTLCache<WitnessNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessNoticeStore, cache: TTLCache<WitnessNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessNotice? {
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

        func save(_ item: WitnessNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessNotice] {
            return inner.list()
        }
    }

    static func newCachedWitnessNoticeStore(_ inner: MemoryWitnessNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessNoticeStore {
        return CachedWitnessNoticeStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness notices. Empty fields match all.
    final class WitnessNoticeQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [WitnessNotice]) -> [WitnessNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessNotices(_ store: any WitnessNoticeStore, query: WitnessNoticeQuery) -> [WitnessNotice] {
        return query.apply(store.list())
    }
}
