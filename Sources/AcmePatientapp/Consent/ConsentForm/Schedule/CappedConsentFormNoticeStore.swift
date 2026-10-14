import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped consent form notices by code.
    protocol CappedConsentFormNoticeStore {
        func find(_ code: String) -> CappedConsentFormNotice?
        func save(_ item: CappedConsentFormNotice)
        func remove(_ code: String) -> Bool
        func list() -> [CappedConsentFormNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedConsentFormNoticeStore: CappedConsentFormNoticeStore {
        var items: [String: CappedConsentFormNotice]
        var order: [String]

        init(items: [String: CappedConsentFormNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedConsentFormNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedConsentFormNotice) {
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

        func list() -> [CappedConsentFormNotice] {
            var out: [CappedConsentFormNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedConsentFormNoticeStore() -> any CappedConsentFormNoticeStore {
        return MemoryCappedConsentFormNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedConsentFormNoticeStore: CappedConsentFormNoticeStore {
        var inner: MemoryCappedConsentFormNoticeStore
        var cache: TTLCache<CappedConsentFormNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedConsentFormNoticeStore, cache: TTLCache<CappedConsentFormNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedConsentFormNotice? {
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

        func save(_ item: CappedConsentFormNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedConsentFormNotice] {
            return inner.list()
        }
    }

    static func newCachedCappedConsentFormNoticeStore(_ inner: MemoryCappedConsentFormNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedConsentFormNoticeStore {
        return CachedCappedConsentFormNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped consent form notices. Empty fields match all.
    final class CappedConsentFormNoticeQuery {
        var source: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRevision: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedConsentFormNotice) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedConsentFormNotice]) -> [CappedConsentFormNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedConsentFormNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedConsentFormNotices(_ store: any CappedConsentFormNoticeStore, query: CappedConsentFormNoticeQuery) -> [CappedConsentFormNotice] {
        return query.apply(store.list())
    }
}
