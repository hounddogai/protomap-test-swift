import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary agreements by code.
    protocol FormularyAgreementStore {
        func find(_ code: String) -> FormularyAgreement?
        func save(_ item: FormularyAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyAgreementStore: FormularyAgreementStore {
        var items: [String: FormularyAgreement]
        var order: [String]

        init(items: [String: FormularyAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyAgreement) {
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

        func list() -> [FormularyAgreement] {
            var out: [FormularyAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyAgreementStore() -> any FormularyAgreementStore {
        return MemoryFormularyAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyAgreementStore: FormularyAgreementStore {
        var inner: MemoryFormularyAgreementStore
        var cache: TTLCache<FormularyAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyAgreementStore, cache: TTLCache<FormularyAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyAgreement? {
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

        func save(_ item: FormularyAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyAgreement] {
            return inner.list()
        }
    }

    static func newCachedFormularyAgreementStore(_ inner: MemoryFormularyAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyAgreementStore {
        return CachedFormularyAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary agreements. Empty fields match all.
    final class FormularyAgreementQuery {
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

        func matches(_ item: FormularyAgreement) -> Bool {
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

        func apply(_ items: [FormularyAgreement]) -> [FormularyAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyAgreements(_ store: any FormularyAgreementStore, query: FormularyAgreementQuery) -> [FormularyAgreement] {
        return query.apply(store.list())
    }
}
