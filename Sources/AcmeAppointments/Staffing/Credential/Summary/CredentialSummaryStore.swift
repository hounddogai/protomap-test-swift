import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential summaries by code.
    protocol CredentialSummaryStore {
        func find(_ code: String) -> CredentialSummary?
        func save(_ item: CredentialSummary)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialSummaryStore: CredentialSummaryStore {
        var items: [String: CredentialSummary]
        var order: [String]

        init(items: [String: CredentialSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialSummary) {
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

        func list() -> [CredentialSummary] {
            var out: [CredentialSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialSummaryStore() -> any CredentialSummaryStore {
        return MemoryCredentialSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialSummaryStore: CredentialSummaryStore {
        var inner: MemoryCredentialSummaryStore
        var cache: TTLCache<CredentialSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialSummaryStore, cache: TTLCache<CredentialSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialSummary? {
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

        func save(_ item: CredentialSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialSummary] {
            return inner.list()
        }
    }

    static func newCachedCredentialSummaryStore(_ inner: MemoryCredentialSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialSummaryStore {
        return CachedCredentialSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential summaries. Empty fields match all.
    final class CredentialSummaryQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialSummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialSummary]) -> [CredentialSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialSummaries(_ store: any CredentialSummaryStore, query: CredentialSummaryQuery) -> [CredentialSummary] {
        return query.apply(store.list())
    }
}
