import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form rollups by code.
    protocol ConsentFormRollupStore {
        func find(_ code: String) -> ConsentFormRollup?
        func save(_ item: ConsentFormRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormRollupStore: ConsentFormRollupStore {
        var items: [String: ConsentFormRollup]
        var order: [String]

        init(items: [String: ConsentFormRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormRollup) {
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

        func list() -> [ConsentFormRollup] {
            var out: [ConsentFormRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormRollupStore() -> any ConsentFormRollupStore {
        return MemoryConsentFormRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormRollupStore: ConsentFormRollupStore {
        var inner: MemoryConsentFormRollupStore
        var cache: TTLCache<ConsentFormRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormRollupStore, cache: TTLCache<ConsentFormRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormRollup? {
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

        func save(_ item: ConsentFormRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormRollup] {
            return inner.list()
        }
    }

    static func newCachedConsentFormRollupStore(_ inner: MemoryConsentFormRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormRollupStore {
        return CachedConsentFormRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form rollups. Empty fields match all.
    final class ConsentFormRollupQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ConsentFormRollup]) -> [ConsentFormRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormRollups(_ store: any ConsentFormRollupStore, query: ConsentFormRollupQuery) -> [ConsentFormRollup] {
        return query.apply(store.list())
    }
}
