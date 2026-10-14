import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default closure requests by code.
    protocol DefaultClosureRequestStore {
        func find(_ code: String) -> DefaultClosureRequest?
        func save(_ item: DefaultClosureRequest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultClosureRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultClosureRequestStore: DefaultClosureRequestStore {
        var items: [String: DefaultClosureRequest]
        var order: [String]

        init(items: [String: DefaultClosureRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultClosureRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultClosureRequest) {
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

        func list() -> [DefaultClosureRequest] {
            var out: [DefaultClosureRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultClosureRequestStore() -> any DefaultClosureRequestStore {
        return MemoryDefaultClosureRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultClosureRequestStore: DefaultClosureRequestStore {
        var inner: MemoryDefaultClosureRequestStore
        var cache: TTLCache<DefaultClosureRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultClosureRequestStore, cache: TTLCache<DefaultClosureRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultClosureRequest? {
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

        func save(_ item: DefaultClosureRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultClosureRequest] {
            return inner.list()
        }
    }

    static func newCachedDefaultClosureRequestStore(_ inner: MemoryDefaultClosureRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultClosureRequestStore {
        return CachedDefaultClosureRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default closure requests. Empty fields match all.
    final class DefaultClosureRequestQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultClosureRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DefaultClosureRequest]) -> [DefaultClosureRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultClosureRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultClosureRequests(_ store: any DefaultClosureRequestStore, query: DefaultClosureRequestQuery) -> [DefaultClosureRequest] {
        return query.apply(store.list())
    }
}
