import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy drafts by code.
    protocol ProxyDraftStore {
        func find(_ code: String) -> ProxyDraft?
        func save(_ item: ProxyDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyDraftStore: ProxyDraftStore {
        var items: [String: ProxyDraft]
        var order: [String]

        init(items: [String: ProxyDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyDraft) {
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

        func list() -> [ProxyDraft] {
            var out: [ProxyDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyDraftStore() -> any ProxyDraftStore {
        return MemoryProxyDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyDraftStore: ProxyDraftStore {
        var inner: MemoryProxyDraftStore
        var cache: TTLCache<ProxyDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyDraftStore, cache: TTLCache<ProxyDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyDraft? {
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

        func save(_ item: ProxyDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyDraft] {
            return inner.list()
        }
    }

    static func newCachedProxyDraftStore(_ inner: MemoryProxyDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyDraftStore {
        return CachedProxyDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy drafts. Empty fields match all.
    final class ProxyDraftQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyDraft]) -> [ProxyDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyDrafts(_ store: any ProxyDraftStore, query: ProxyDraftQuery) -> [ProxyDraft] {
        return query.apply(store.list())
    }
}
