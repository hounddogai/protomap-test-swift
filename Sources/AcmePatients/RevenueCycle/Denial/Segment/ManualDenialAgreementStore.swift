import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual denial agreements by code.
    protocol ManualDenialAgreementStore {
        func find(_ code: String) -> ManualDenialAgreement?
        func save(_ item: ManualDenialAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDenialAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDenialAgreementStore: ManualDenialAgreementStore {
        var items: [String: ManualDenialAgreement]
        var order: [String]

        init(items: [String: ManualDenialAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDenialAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDenialAgreement) {
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

        func list() -> [ManualDenialAgreement] {
            var out: [ManualDenialAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDenialAgreementStore() -> any ManualDenialAgreementStore {
        return MemoryManualDenialAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDenialAgreementStore: ManualDenialAgreementStore {
        var inner: MemoryManualDenialAgreementStore
        var cache: TTLCache<ManualDenialAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDenialAgreementStore, cache: TTLCache<ManualDenialAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDenialAgreement? {
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

        func save(_ item: ManualDenialAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDenialAgreement] {
            return inner.list()
        }
    }

    static func newCachedManualDenialAgreementStore(_ inner: MemoryManualDenialAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDenialAgreementStore {
        return CachedManualDenialAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual denial agreements. Empty fields match all.
    final class ManualDenialAgreementQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDenialAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDenialAgreement]) -> [ManualDenialAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDenialAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDenialAgreements(_ store: any ManualDenialAgreementStore, query: ManualDenialAgreementQuery) -> [ManualDenialAgreement] {
        return query.apply(store.list())
    }
}
