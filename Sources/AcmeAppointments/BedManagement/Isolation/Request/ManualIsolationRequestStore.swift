import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual isolation requests by code.
    protocol ManualIsolationRequestStore {
        func find(_ code: String) -> ManualIsolationRequest?
        func save(_ item: ManualIsolationRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualIsolationRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualIsolationRequestStore: ManualIsolationRequestStore {
        var items: [String: ManualIsolationRequest]
        var order: [String]

        init(items: [String: ManualIsolationRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualIsolationRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualIsolationRequest) {
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

        func list() -> [ManualIsolationRequest] {
            var out: [ManualIsolationRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualIsolationRequestStore() -> any ManualIsolationRequestStore {
        return MemoryManualIsolationRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualIsolationRequestStore: ManualIsolationRequestStore {
        var inner: MemoryManualIsolationRequestStore
        var cache: TTLCache<ManualIsolationRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualIsolationRequestStore, cache: TTLCache<ManualIsolationRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualIsolationRequest? {
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

        func save(_ item: ManualIsolationRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualIsolationRequest] {
            return inner.list()
        }
    }

    static func newCachedManualIsolationRequestStore(_ inner: MemoryManualIsolationRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualIsolationRequestStore {
        return CachedManualIsolationRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual isolation requests. Empty fields match all.
    final class ManualIsolationRequestQuery {
        var unit: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualIsolationRequest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualIsolationRequest]) -> [ManualIsolationRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualIsolationRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualIsolationRequests(_ store: any ManualIsolationRequestStore, query: ManualIsolationRequestQuery) -> [ManualIsolationRequest] {
        return query.apply(store.list())
    }
}
