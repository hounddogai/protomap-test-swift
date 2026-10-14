import AcmePlatform
import Foundation

extension Labs {
    /// Keeps lenient result agreements by code.
    protocol LenientResultAgreementStore {
        func find(_ code: String) -> LenientResultAgreement?
        func save(_ item: LenientResultAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [LenientResultAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientResultAgreementStore: LenientResultAgreementStore {
        var items: [String: LenientResultAgreement]
        var order: [String]

        init(items: [String: LenientResultAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientResultAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientResultAgreement) {
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

        func list() -> [LenientResultAgreement] {
            var out: [LenientResultAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientResultAgreementStore() -> any LenientResultAgreementStore {
        return MemoryLenientResultAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientResultAgreementStore: LenientResultAgreementStore {
        var inner: MemoryLenientResultAgreementStore
        var cache: TTLCache<LenientResultAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientResultAgreementStore, cache: TTLCache<LenientResultAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientResultAgreement? {
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

        func save(_ item: LenientResultAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientResultAgreement] {
            return inner.list()
        }
    }

    static func newCachedLenientResultAgreementStore(_ inner: MemoryLenientResultAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientResultAgreementStore {
        return CachedLenientResultAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient result agreements. Empty fields match all.
    final class LenientResultAgreementQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientResultAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientResultAgreement]) -> [LenientResultAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientResultAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientResultAgreements(_ store: any LenientResultAgreementStore, query: LenientResultAgreementQuery) -> [LenientResultAgreement] {
        return query.apply(store.list())
    }
}
