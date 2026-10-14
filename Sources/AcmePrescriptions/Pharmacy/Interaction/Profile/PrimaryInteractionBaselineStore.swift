import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary interaction baselines by code.
    protocol PrimaryInteractionBaselineStore {
        func find(_ code: String) -> PrimaryInteractionBaseline?
        func save(_ item: PrimaryInteractionBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryInteractionBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryInteractionBaselineStore: PrimaryInteractionBaselineStore {
        var items: [String: PrimaryInteractionBaseline]
        var order: [String]

        init(items: [String: PrimaryInteractionBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryInteractionBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryInteractionBaseline) {
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

        func list() -> [PrimaryInteractionBaseline] {
            var out: [PrimaryInteractionBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryInteractionBaselineStore() -> any PrimaryInteractionBaselineStore {
        return MemoryPrimaryInteractionBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryInteractionBaselineStore: PrimaryInteractionBaselineStore {
        var inner: MemoryPrimaryInteractionBaselineStore
        var cache: TTLCache<PrimaryInteractionBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryInteractionBaselineStore, cache: TTLCache<PrimaryInteractionBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryInteractionBaseline? {
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

        func save(_ item: PrimaryInteractionBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryInteractionBaseline] {
            return inner.list()
        }
    }

    static func newCachedPrimaryInteractionBaselineStore(_ inner: MemoryPrimaryInteractionBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryInteractionBaselineStore {
        return CachedPrimaryInteractionBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary interaction baselines. Empty fields match all.
    final class PrimaryInteractionBaselineQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryInteractionBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PrimaryInteractionBaseline]) -> [PrimaryInteractionBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryInteractionBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryInteractionBaselines(_ store: any PrimaryInteractionBaselineStore, query: PrimaryInteractionBaselineQuery) -> [PrimaryInteractionBaseline] {
        return query.apply(store.list())
    }
}
