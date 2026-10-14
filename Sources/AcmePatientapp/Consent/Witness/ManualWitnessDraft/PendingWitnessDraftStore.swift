import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending witness drafts by code.
    protocol PendingWitnessDraftStore {
        func find(_ code: String) -> PendingWitnessDraft?
        func save(_ item: PendingWitnessDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PendingWitnessDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingWitnessDraftStore: PendingWitnessDraftStore {
        var items: [String: PendingWitnessDraft]
        var order: [String]

        init(items: [String: PendingWitnessDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingWitnessDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingWitnessDraft) {
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

        func list() -> [PendingWitnessDraft] {
            var out: [PendingWitnessDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingWitnessDraftStore() -> any PendingWitnessDraftStore {
        return MemoryPendingWitnessDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingWitnessDraftStore: PendingWitnessDraftStore {
        var inner: MemoryPendingWitnessDraftStore
        var cache: TTLCache<PendingWitnessDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingWitnessDraftStore, cache: TTLCache<PendingWitnessDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingWitnessDraft? {
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

        func save(_ item: PendingWitnessDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingWitnessDraft] {
            return inner.list()
        }
    }

    static func newCachedPendingWitnessDraftStore(_ inner: MemoryPendingWitnessDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingWitnessDraftStore {
        return CachedPendingWitnessDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending witness drafts. Empty fields match all.
    final class PendingWitnessDraftQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingWitnessDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PendingWitnessDraft]) -> [PendingWitnessDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingWitnessDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingWitnessDrafts(_ store: any PendingWitnessDraftStore, query: PendingWitnessDraftQuery) -> [PendingWitnessDraft] {
        return query.apply(store.list())
    }
}
