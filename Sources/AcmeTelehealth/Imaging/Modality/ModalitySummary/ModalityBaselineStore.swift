import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality baselines by code.
    protocol ModalityBaselineStore {
        func find(_ code: String) -> ModalityBaseline?
        func save(_ item: ModalityBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityBaselineStore: ModalityBaselineStore {
        var items: [String: ModalityBaseline]
        var order: [String]

        init(items: [String: ModalityBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityBaseline) {
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

        func list() -> [ModalityBaseline] {
            var out: [ModalityBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityBaselineStore() -> any ModalityBaselineStore {
        return MemoryModalityBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityBaselineStore: ModalityBaselineStore {
        var inner: MemoryModalityBaselineStore
        var cache: TTLCache<ModalityBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityBaselineStore, cache: TTLCache<ModalityBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityBaseline? {
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

        func save(_ item: ModalityBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityBaseline] {
            return inner.list()
        }
    }

    static func newCachedModalityBaselineStore(_ inner: MemoryModalityBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityBaselineStore {
        return CachedModalityBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality baselines. Empty fields match all.
    final class ModalityBaselineQuery {
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

        func matches(_ item: ModalityBaseline) -> Bool {
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

        func apply(_ items: [ModalityBaseline]) -> [ModalityBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityBaselines(_ store: any ModalityBaselineStore, query: ModalityBaselineQuery) -> [ModalityBaseline] {
        return query.apply(store.list())
    }
}
