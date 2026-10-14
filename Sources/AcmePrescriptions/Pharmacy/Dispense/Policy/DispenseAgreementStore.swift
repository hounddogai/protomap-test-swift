import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense agreements by code.
    protocol DispenseAgreementStore {
        func find(_ code: String) -> DispenseAgreement?
        func save(_ item: DispenseAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseAgreementStore: DispenseAgreementStore {
        var items: [String: DispenseAgreement]
        var order: [String]

        init(items: [String: DispenseAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseAgreement) {
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

        func list() -> [DispenseAgreement] {
            var out: [DispenseAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseAgreementStore() -> any DispenseAgreementStore {
        return MemoryDispenseAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseAgreementStore: DispenseAgreementStore {
        var inner: MemoryDispenseAgreementStore
        var cache: TTLCache<DispenseAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseAgreementStore, cache: TTLCache<DispenseAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseAgreement? {
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

        func save(_ item: DispenseAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseAgreement] {
            return inner.list()
        }
    }

    static func newCachedDispenseAgreementStore(_ inner: MemoryDispenseAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseAgreementStore {
        return CachedDispenseAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense agreements. Empty fields match all.
    final class DispenseAgreementQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseAgreement]) -> [DispenseAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseAgreements(_ store: any DispenseAgreementStore, query: DispenseAgreementQuery) -> [DispenseAgreement] {
        return query.apply(store.list())
    }
}
