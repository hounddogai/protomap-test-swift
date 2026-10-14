import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual overtime digests by code.
    protocol ManualOvertimeDigestStore {
        func find(_ code: String) -> ManualOvertimeDigest?
        func save(_ item: ManualOvertimeDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOvertimeDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOvertimeDigestStore: ManualOvertimeDigestStore {
        var items: [String: ManualOvertimeDigest]
        var order: [String]

        init(items: [String: ManualOvertimeDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOvertimeDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOvertimeDigest) {
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

        func list() -> [ManualOvertimeDigest] {
            var out: [ManualOvertimeDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOvertimeDigestStore() -> any ManualOvertimeDigestStore {
        return MemoryManualOvertimeDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOvertimeDigestStore: ManualOvertimeDigestStore {
        var inner: MemoryManualOvertimeDigestStore
        var cache: TTLCache<ManualOvertimeDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOvertimeDigestStore, cache: TTLCache<ManualOvertimeDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOvertimeDigest? {
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

        func save(_ item: ManualOvertimeDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOvertimeDigest] {
            return inner.list()
        }
    }

    static func newCachedManualOvertimeDigestStore(_ inner: MemoryManualOvertimeDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOvertimeDigestStore {
        return CachedManualOvertimeDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual overtime digests. Empty fields match all.
    final class ManualOvertimeDigestQuery {
        var category: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCopay: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOvertimeDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualOvertimeDigest]) -> [ManualOvertimeDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOvertimeDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOvertimeDigests(_ store: any ManualOvertimeDigestStore, query: ManualOvertimeDigestQuery) -> [ManualOvertimeDigest] {
        return query.apply(store.list())
    }
}
