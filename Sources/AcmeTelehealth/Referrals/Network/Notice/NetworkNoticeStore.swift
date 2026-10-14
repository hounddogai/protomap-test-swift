import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network notices by code.
    protocol NetworkNoticeStore {
        func find(_ code: String) -> NetworkNotice?
        func save(_ item: NetworkNotice)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkNoticeStore: NetworkNoticeStore {
        var items: [String: NetworkNotice]
        var order: [String]

        init(items: [String: NetworkNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkNotice) {
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

        func list() -> [NetworkNotice] {
            var out: [NetworkNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkNoticeStore() -> any NetworkNoticeStore {
        return MemoryNetworkNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkNoticeStore: NetworkNoticeStore {
        var inner: MemoryNetworkNoticeStore
        var cache: TTLCache<NetworkNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkNoticeStore, cache: TTLCache<NetworkNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkNotice? {
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

        func save(_ item: NetworkNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkNotice] {
            return inner.list()
        }
    }

    static func newCachedNetworkNoticeStore(_ inner: MemoryNetworkNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkNoticeStore {
        return CachedNetworkNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network notices. Empty fields match all.
    final class NetworkNoticeQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkNotice) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkNotice]) -> [NetworkNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkNotices(_ store: any NetworkNoticeStore, query: NetworkNoticeQuery) -> [NetworkNotice] {
        return query.apply(store.list())
    }
}
