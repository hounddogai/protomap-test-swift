import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered revocation baselines by code.
    protocol TieredRevocationBaselineStore {
        func find(_ code: String) -> TieredRevocationBaseline?
        func save(_ item: TieredRevocationBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRevocationBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRevocationBaselineStore: TieredRevocationBaselineStore {
        var items: [String: TieredRevocationBaseline]
        var order: [String]

        init(items: [String: TieredRevocationBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRevocationBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRevocationBaseline) {
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

        func list() -> [TieredRevocationBaseline] {
            var out: [TieredRevocationBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRevocationBaselineStore() -> any TieredRevocationBaselineStore {
        return MemoryTieredRevocationBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRevocationBaselineStore: TieredRevocationBaselineStore {
        var inner: MemoryTieredRevocationBaselineStore
        var cache: TTLCache<TieredRevocationBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRevocationBaselineStore, cache: TTLCache<TieredRevocationBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRevocationBaseline? {
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

        func save(_ item: TieredRevocationBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRevocationBaseline] {
            return inner.list()
        }
    }

    static func newCachedTieredRevocationBaselineStore(_ inner: MemoryTieredRevocationBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRevocationBaselineStore {
        return CachedTieredRevocationBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered revocation baselines. Empty fields match all.
    final class TieredRevocationBaselineQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRevocationBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TieredRevocationBaseline]) -> [TieredRevocationBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRevocationBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRevocationBaselines(_ store: any TieredRevocationBaselineStore, query: TieredRevocationBaselineQuery) -> [TieredRevocationBaseline] {
        return query.apply(store.list())
    }
}
