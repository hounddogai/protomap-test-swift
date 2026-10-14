import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read agreements by code.
    protocol ReadAgreementStore {
        func find(_ code: String) -> ReadAgreement?
        func save(_ item: ReadAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ReadAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadAgreementStore: ReadAgreementStore {
        var items: [String: ReadAgreement]
        var order: [String]

        init(items: [String: ReadAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadAgreement) {
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

        func list() -> [ReadAgreement] {
            var out: [ReadAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadAgreementStore() -> any ReadAgreementStore {
        return MemoryReadAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadAgreementStore: ReadAgreementStore {
        var inner: MemoryReadAgreementStore
        var cache: TTLCache<ReadAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadAgreementStore, cache: TTLCache<ReadAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadAgreement? {
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

        func save(_ item: ReadAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadAgreement] {
            return inner.list()
        }
    }

    static func newCachedReadAgreementStore(_ inner: MemoryReadAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadAgreementStore {
        return CachedReadAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read agreements. Empty fields match all.
    final class ReadAgreementQuery {
        var unit: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minWeight: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadAgreement) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadAgreement]) -> [ReadAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadAgreements(_ store: any ReadAgreementStore, query: ReadAgreementQuery) -> [ReadAgreement] {
        return query.apply(store.list())
    }
}
