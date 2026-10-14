import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation adjustments by code.
    protocol RevocationAdjustmentStore {
        func find(_ code: String) -> RevocationAdjustment?
        func save(_ item: RevocationAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationAdjustmentStore: RevocationAdjustmentStore {
        var items: [String: RevocationAdjustment]
        var order: [String]

        init(items: [String: RevocationAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationAdjustment) {
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

        func list() -> [RevocationAdjustment] {
            var out: [RevocationAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationAdjustmentStore() -> any RevocationAdjustmentStore {
        return MemoryRevocationAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationAdjustmentStore: RevocationAdjustmentStore {
        var inner: MemoryRevocationAdjustmentStore
        var cache: TTLCache<RevocationAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationAdjustmentStore, cache: TTLCache<RevocationAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationAdjustment? {
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

        func save(_ item: RevocationAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationAdjustment] {
            return inner.list()
        }
    }

    static func newCachedRevocationAdjustmentStore(_ inner: MemoryRevocationAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationAdjustmentStore {
        return CachedRevocationAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation adjustments. Empty fields match all.
    final class RevocationAdjustmentQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationAdjustment]) -> [RevocationAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationAdjustments(_ store: any RevocationAdjustmentStore, query: RevocationAdjustmentQuery) -> [RevocationAdjustment] {
        return query.apply(store.list())
    }
}
