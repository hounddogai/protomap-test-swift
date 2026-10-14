import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result agreements by code.
    protocol ResultAgreementStore {
        func find(_ code: String) -> ResultAgreement?
        func save(_ item: ResultAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ResultAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultAgreementStore: ResultAgreementStore {
        var items: [String: ResultAgreement]
        var order: [String]

        init(items: [String: ResultAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultAgreement) {
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

        func list() -> [ResultAgreement] {
            var out: [ResultAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultAgreementStore() -> any ResultAgreementStore {
        return MemoryResultAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultAgreementStore: ResultAgreementStore {
        var inner: MemoryResultAgreementStore
        var cache: TTLCache<ResultAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultAgreementStore, cache: TTLCache<ResultAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultAgreement? {
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

        func save(_ item: ResultAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultAgreement] {
            return inner.list()
        }
    }

    static func newCachedResultAgreementStore(_ inner: MemoryResultAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultAgreementStore {
        return CachedResultAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result agreements. Empty fields match all.
    final class ResultAgreementQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ResultAgreement]) -> [ResultAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultAgreements(_ store: any ResultAgreementStore, query: ResultAgreementQuery) -> [ResultAgreement] {
        return query.apply(store.list())
    }
}
