import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form notices by code.
    protocol ConsentFormNoticeStore {
        func find(_ code: String) -> ConsentFormNotice?
        func save(_ item: ConsentFormNotice)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormNoticeStore: ConsentFormNoticeStore {
        var items: [String: ConsentFormNotice]
        var order: [String]

        init(items: [String: ConsentFormNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormNotice) {
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

        func list() -> [ConsentFormNotice] {
            var out: [ConsentFormNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormNoticeStore() -> any ConsentFormNoticeStore {
        return MemoryConsentFormNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormNoticeStore: ConsentFormNoticeStore {
        var inner: MemoryConsentFormNoticeStore
        var cache: TTLCache<ConsentFormNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormNoticeStore, cache: TTLCache<ConsentFormNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormNotice? {
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

        func save(_ item: ConsentFormNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormNotice] {
            return inner.list()
        }
    }

    static func newCachedConsentFormNoticeStore(_ inner: MemoryConsentFormNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormNoticeStore {
        return CachedConsentFormNoticeStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form notices. Empty fields match all.
    final class ConsentFormNoticeQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ConsentFormNotice]) -> [ConsentFormNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormNotices(_ store: any ConsentFormNoticeStore, query: ConsentFormNoticeQuery) -> [ConsentFormNotice] {
        return query.apply(store.list())
    }
}
