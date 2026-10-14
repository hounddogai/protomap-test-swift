import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential baselines by code.
    protocol CredentialBaselineStore {
        func find(_ code: String) -> CredentialBaseline?
        func save(_ item: CredentialBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialBaselineStore: CredentialBaselineStore {
        var items: [String: CredentialBaseline]
        var order: [String]

        init(items: [String: CredentialBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialBaseline) {
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

        func list() -> [CredentialBaseline] {
            var out: [CredentialBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialBaselineStore() -> any CredentialBaselineStore {
        return MemoryCredentialBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialBaselineStore: CredentialBaselineStore {
        var inner: MemoryCredentialBaselineStore
        var cache: TTLCache<CredentialBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialBaselineStore, cache: TTLCache<CredentialBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialBaseline? {
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

        func save(_ item: CredentialBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialBaseline] {
            return inner.list()
        }
    }

    static func newCachedCredentialBaselineStore(_ inner: MemoryCredentialBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialBaselineStore {
        return CachedCredentialBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential baselines. Empty fields match all.
    final class CredentialBaselineQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CredentialBaseline]) -> [CredentialBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialBaselines(_ store: any CredentialBaselineStore, query: CredentialBaselineQuery) -> [CredentialBaseline] {
        return query.apply(store.list())
    }
}
