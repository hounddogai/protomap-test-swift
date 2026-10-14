import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential estimates by code.
    protocol CredentialEstimateStore {
        func find(_ code: String) -> CredentialEstimate?
        func save(_ item: CredentialEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialEstimateStore: CredentialEstimateStore {
        var items: [String: CredentialEstimate]
        var order: [String]

        init(items: [String: CredentialEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialEstimate) {
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

        func list() -> [CredentialEstimate] {
            var out: [CredentialEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialEstimateStore() -> any CredentialEstimateStore {
        return MemoryCredentialEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialEstimateStore: CredentialEstimateStore {
        var inner: MemoryCredentialEstimateStore
        var cache: TTLCache<CredentialEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialEstimateStore, cache: TTLCache<CredentialEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialEstimate? {
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

        func save(_ item: CredentialEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialEstimate] {
            return inner.list()
        }
    }

    static func newCachedCredentialEstimateStore(_ inner: MemoryCredentialEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialEstimateStore {
        return CachedCredentialEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential estimates. Empty fields match all.
    final class CredentialEstimateQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialEstimate]) -> [CredentialEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialEstimates(_ store: any CredentialEstimateStore, query: CredentialEstimateQuery) -> [CredentialEstimate] {
        return query.apply(store.list())
    }
}
