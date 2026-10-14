import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation baselines by code.
    protocol RevocationBaselineStore {
        func find(_ code: String) -> RevocationBaseline?
        func save(_ item: RevocationBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationBaselineStore: RevocationBaselineStore {
        var items: [String: RevocationBaseline]
        var order: [String]

        init(items: [String: RevocationBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationBaseline) {
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

        func list() -> [RevocationBaseline] {
            var out: [RevocationBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationBaselineStore() -> any RevocationBaselineStore {
        return MemoryRevocationBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationBaselineStore: RevocationBaselineStore {
        var inner: MemoryRevocationBaselineStore
        var cache: TTLCache<RevocationBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationBaselineStore, cache: TTLCache<RevocationBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationBaseline? {
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

        func save(_ item: RevocationBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationBaseline] {
            return inner.list()
        }
    }

    static func newCachedRevocationBaselineStore(_ inner: MemoryRevocationBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationBaselineStore {
        return CachedRevocationBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation baselines. Empty fields match all.
    final class RevocationBaselineQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationBaseline]) -> [RevocationBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationBaselines(_ store: any RevocationBaselineStore, query: RevocationBaselineQuery) -> [RevocationBaseline] {
        return query.apply(store.list())
    }
}
