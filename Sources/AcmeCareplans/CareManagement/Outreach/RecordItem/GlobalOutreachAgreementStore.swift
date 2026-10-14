import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global outreach agreements by code.
    protocol GlobalOutreachAgreementStore {
        func find(_ code: String) -> GlobalOutreachAgreement?
        func save(_ item: GlobalOutreachAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalOutreachAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalOutreachAgreementStore: GlobalOutreachAgreementStore {
        var items: [String: GlobalOutreachAgreement]
        var order: [String]

        init(items: [String: GlobalOutreachAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalOutreachAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalOutreachAgreement) {
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

        func list() -> [GlobalOutreachAgreement] {
            var out: [GlobalOutreachAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalOutreachAgreementStore() -> any GlobalOutreachAgreementStore {
        return MemoryGlobalOutreachAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalOutreachAgreementStore: GlobalOutreachAgreementStore {
        var inner: MemoryGlobalOutreachAgreementStore
        var cache: TTLCache<GlobalOutreachAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalOutreachAgreementStore, cache: TTLCache<GlobalOutreachAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalOutreachAgreement? {
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

        func save(_ item: GlobalOutreachAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalOutreachAgreement] {
            return inner.list()
        }
    }

    static func newCachedGlobalOutreachAgreementStore(_ inner: MemoryGlobalOutreachAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalOutreachAgreementStore {
        return CachedGlobalOutreachAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global outreach agreements. Empty fields match all.
    final class GlobalOutreachAgreementQuery {
        var source: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalOutreachAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalOutreachAgreement]) -> [GlobalOutreachAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalOutreachAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalOutreachAgreements(_ store: any GlobalOutreachAgreementStore, query: GlobalOutreachAgreementQuery) -> [GlobalOutreachAgreement] {
        return query.apply(store.list())
    }
}
