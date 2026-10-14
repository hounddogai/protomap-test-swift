import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient proxy drafts by code.
    protocol LenientProxyDraftStore {
        func find(_ code: String) -> LenientProxyDraft?
        func save(_ item: LenientProxyDraft)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProxyDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProxyDraftStore: LenientProxyDraftStore {
        var items: [String: LenientProxyDraft]
        var order: [String]

        init(items: [String: LenientProxyDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProxyDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProxyDraft) {
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

        func list() -> [LenientProxyDraft] {
            var out: [LenientProxyDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProxyDraftStore() -> any LenientProxyDraftStore {
        return MemoryLenientProxyDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProxyDraftStore: LenientProxyDraftStore {
        var inner: MemoryLenientProxyDraftStore
        var cache: TTLCache<LenientProxyDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProxyDraftStore, cache: TTLCache<LenientProxyDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProxyDraft? {
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

        func save(_ item: LenientProxyDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProxyDraft] {
            return inner.list()
        }
    }

    static func newCachedLenientProxyDraftStore(_ inner: MemoryLenientProxyDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProxyDraftStore {
        return CachedLenientProxyDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient proxy drafts. Empty fields match all.
    final class LenientProxyDraftQuery {
        var locale: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProxyDraft) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProxyDraft]) -> [LenientProxyDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProxyDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProxyDrafts(_ store: any LenientProxyDraftStore, query: LenientProxyDraftQuery) -> [LenientProxyDraft] {
        return query.apply(store.list())
    }
}
