import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual specimen agreements by code.
    protocol ManualSpecimenAgreementStore {
        func find(_ code: String) -> ManualSpecimenAgreement?
        func save(_ item: ManualSpecimenAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ManualSpecimenAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualSpecimenAgreementStore: ManualSpecimenAgreementStore {
        var items: [String: ManualSpecimenAgreement]
        var order: [String]

        init(items: [String: ManualSpecimenAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualSpecimenAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualSpecimenAgreement) {
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

        func list() -> [ManualSpecimenAgreement] {
            var out: [ManualSpecimenAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualSpecimenAgreementStore() -> any ManualSpecimenAgreementStore {
        return MemoryManualSpecimenAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualSpecimenAgreementStore: ManualSpecimenAgreementStore {
        var inner: MemoryManualSpecimenAgreementStore
        var cache: TTLCache<ManualSpecimenAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualSpecimenAgreementStore, cache: TTLCache<ManualSpecimenAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualSpecimenAgreement? {
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

        func save(_ item: ManualSpecimenAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualSpecimenAgreement] {
            return inner.list()
        }
    }

    static func newCachedManualSpecimenAgreementStore(_ inner: MemoryManualSpecimenAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualSpecimenAgreementStore {
        return CachedManualSpecimenAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual specimen agreements. Empty fields match all.
    final class ManualSpecimenAgreementQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualSpecimenAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualSpecimenAgreement]) -> [ManualSpecimenAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualSpecimenAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualSpecimenAgreements(_ store: any ManualSpecimenAgreementStore, query: ManualSpecimenAgreementQuery) -> [ManualSpecimenAgreement] {
        return query.apply(store.list())
    }
}
