import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual census drafts by code.
    protocol ManualCensusDraftStore {
        func find(_ code: String) -> ManualCensusDraft?
        func save(_ item: ManualCensusDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCensusDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCensusDraftStore: ManualCensusDraftStore {
        var items: [String: ManualCensusDraft]
        var order: [String]

        init(items: [String: ManualCensusDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCensusDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCensusDraft) {
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

        func list() -> [ManualCensusDraft] {
            var out: [ManualCensusDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCensusDraftStore() -> any ManualCensusDraftStore {
        return MemoryManualCensusDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCensusDraftStore: ManualCensusDraftStore {
        var inner: MemoryManualCensusDraftStore
        var cache: TTLCache<ManualCensusDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCensusDraftStore, cache: TTLCache<ManualCensusDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCensusDraft? {
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

        func save(_ item: ManualCensusDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCensusDraft] {
            return inner.list()
        }
    }

    static func newCachedManualCensusDraftStore(_ inner: MemoryManualCensusDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCensusDraftStore {
        return CachedManualCensusDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual census drafts. Empty fields match all.
    final class ManualCensusDraftQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCensusDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCensusDraft]) -> [ManualCensusDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCensusDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCensusDrafts(_ store: any ManualCensusDraftStore, query: ManualCensusDraftQuery) -> [ManualCensusDraft] {
        return query.apply(store.list())
    }
}
