import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation rollups by code.
    protocol RevocationRollupStore {
        func find(_ code: String) -> RevocationRollup?
        func save(_ item: RevocationRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationRollupStore: RevocationRollupStore {
        var items: [String: RevocationRollup]
        var order: [String]

        init(items: [String: RevocationRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationRollup) {
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

        func list() -> [RevocationRollup] {
            var out: [RevocationRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationRollupStore() -> any RevocationRollupStore {
        return MemoryRevocationRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationRollupStore: RevocationRollupStore {
        var inner: MemoryRevocationRollupStore
        var cache: TTLCache<RevocationRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationRollupStore, cache: TTLCache<RevocationRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationRollup? {
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

        func save(_ item: RevocationRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationRollup] {
            return inner.list()
        }
    }

    static func newCachedRevocationRollupStore(_ inner: MemoryRevocationRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationRollupStore {
        return CachedRevocationRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation rollups. Empty fields match all.
    final class RevocationRollupQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationRollup]) -> [RevocationRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationRollups(_ store: any RevocationRollupStore, query: RevocationRollupQuery) -> [RevocationRollup] {
        return query.apply(store.list())
    }
}
