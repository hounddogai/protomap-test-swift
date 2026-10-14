import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled network drafts by code.
    protocol ScheduledNetworkDraftStore {
        func find(_ code: String) -> ScheduledNetworkDraft?
        func save(_ item: ScheduledNetworkDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledNetworkDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledNetworkDraftStore: ScheduledNetworkDraftStore {
        var items: [String: ScheduledNetworkDraft]
        var order: [String]

        init(items: [String: ScheduledNetworkDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledNetworkDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledNetworkDraft) {
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

        func list() -> [ScheduledNetworkDraft] {
            var out: [ScheduledNetworkDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledNetworkDraftStore() -> any ScheduledNetworkDraftStore {
        return MemoryScheduledNetworkDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledNetworkDraftStore: ScheduledNetworkDraftStore {
        var inner: MemoryScheduledNetworkDraftStore
        var cache: TTLCache<ScheduledNetworkDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledNetworkDraftStore, cache: TTLCache<ScheduledNetworkDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledNetworkDraft? {
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

        func save(_ item: ScheduledNetworkDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledNetworkDraft] {
            return inner.list()
        }
    }

    static func newCachedScheduledNetworkDraftStore(_ inner: MemoryScheduledNetworkDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledNetworkDraftStore {
        return CachedScheduledNetworkDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled network drafts. Empty fields match all.
    final class ScheduledNetworkDraftQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledNetworkDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ScheduledNetworkDraft]) -> [ScheduledNetworkDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledNetworkDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledNetworkDrafts(_ store: any ScheduledNetworkDraftStore, query: ScheduledNetworkDraftQuery) -> [ScheduledNetworkDraft] {
        return query.apply(store.list())
    }
}
