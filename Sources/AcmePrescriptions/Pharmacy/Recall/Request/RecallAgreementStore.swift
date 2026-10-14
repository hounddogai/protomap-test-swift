import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall agreements by code.
    protocol RecallAgreementStore {
        func find(_ code: String) -> RecallAgreement?
        func save(_ item: RecallAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RecallAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallAgreementStore: RecallAgreementStore {
        var items: [String: RecallAgreement]
        var order: [String]

        init(items: [String: RecallAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallAgreement) {
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

        func list() -> [RecallAgreement] {
            var out: [RecallAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallAgreementStore() -> any RecallAgreementStore {
        return MemoryRecallAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallAgreementStore: RecallAgreementStore {
        var inner: MemoryRecallAgreementStore
        var cache: TTLCache<RecallAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallAgreementStore, cache: TTLCache<RecallAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallAgreement? {
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

        func save(_ item: RecallAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallAgreement] {
            return inner.list()
        }
    }

    static func newCachedRecallAgreementStore(_ inner: MemoryRecallAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallAgreementStore {
        return CachedRecallAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall agreements. Empty fields match all.
    final class RecallAgreementQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallAgreement]) -> [RecallAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallAgreements(_ store: any RecallAgreementStore, query: RecallAgreementQuery) -> [RecallAgreement] {
        return query.apply(store.list())
    }
}
