import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient bed board drafts by code.
    protocol LenientBedBoardDraftStore {
        func find(_ code: String) -> LenientBedBoardDraft?
        func save(_ item: LenientBedBoardDraft)
        func remove(_ code: String) -> Bool
        func list() -> [LenientBedBoardDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientBedBoardDraftStore: LenientBedBoardDraftStore {
        var items: [String: LenientBedBoardDraft]
        var order: [String]

        init(items: [String: LenientBedBoardDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientBedBoardDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientBedBoardDraft) {
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

        func list() -> [LenientBedBoardDraft] {
            var out: [LenientBedBoardDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientBedBoardDraftStore() -> any LenientBedBoardDraftStore {
        return MemoryLenientBedBoardDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientBedBoardDraftStore: LenientBedBoardDraftStore {
        var inner: MemoryLenientBedBoardDraftStore
        var cache: TTLCache<LenientBedBoardDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientBedBoardDraftStore, cache: TTLCache<LenientBedBoardDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientBedBoardDraft? {
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

        func save(_ item: LenientBedBoardDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientBedBoardDraft] {
            return inner.list()
        }
    }

    static func newCachedLenientBedBoardDraftStore(_ inner: MemoryLenientBedBoardDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientBedBoardDraftStore {
        return CachedLenientBedBoardDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient bed board drafts. Empty fields match all.
    final class LenientBedBoardDraftQuery {
        var locale: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCopay: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientBedBoardDraft) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientBedBoardDraft]) -> [LenientBedBoardDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientBedBoardDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientBedBoardDrafts(_ store: any LenientBedBoardDraftStore, query: LenientBedBoardDraftQuery) -> [LenientBedBoardDraft] {
        return query.apply(store.list())
    }
}
