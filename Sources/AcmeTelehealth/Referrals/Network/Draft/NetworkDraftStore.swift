import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network drafts by code.
    protocol NetworkDraftStore {
        func find(_ code: String) -> NetworkDraft?
        func save(_ item: NetworkDraft)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkDraftStore: NetworkDraftStore {
        var items: [String: NetworkDraft]
        var order: [String]

        init(items: [String: NetworkDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkDraft) {
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

        func list() -> [NetworkDraft] {
            var out: [NetworkDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkDraftStore() -> any NetworkDraftStore {
        return MemoryNetworkDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkDraftStore: NetworkDraftStore {
        var inner: MemoryNetworkDraftStore
        var cache: TTLCache<NetworkDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkDraftStore, cache: TTLCache<NetworkDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkDraft? {
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

        func save(_ item: NetworkDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkDraft] {
            return inner.list()
        }
    }

    static func newCachedNetworkDraftStore(_ inner: MemoryNetworkDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkDraftStore {
        return CachedNetworkDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network drafts. Empty fields match all.
    final class NetworkDraftQuery {
        var region: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minSequence: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkDraft) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkDraft]) -> [NetworkDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkDrafts(_ store: any NetworkDraftStore, query: NetworkDraftQuery) -> [NetworkDraft] {
        return query.apply(store.list())
    }
}
