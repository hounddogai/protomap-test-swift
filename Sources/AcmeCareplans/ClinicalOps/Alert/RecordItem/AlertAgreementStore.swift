import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert agreements by code.
    protocol AlertAgreementStore {
        func find(_ code: String) -> AlertAgreement?
        func save(_ item: AlertAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [AlertAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertAgreementStore: AlertAgreementStore {
        var items: [String: AlertAgreement]
        var order: [String]

        init(items: [String: AlertAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertAgreement) {
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

        func list() -> [AlertAgreement] {
            var out: [AlertAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertAgreementStore() -> any AlertAgreementStore {
        return MemoryAlertAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertAgreementStore: AlertAgreementStore {
        var inner: MemoryAlertAgreementStore
        var cache: TTLCache<AlertAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertAgreementStore, cache: TTLCache<AlertAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertAgreement? {
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

        func save(_ item: AlertAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertAgreement] {
            return inner.list()
        }
    }

    static func newCachedAlertAgreementStore(_ inner: MemoryAlertAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertAgreementStore {
        return CachedAlertAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert agreements. Empty fields match all.
    final class AlertAgreementQuery {
        var segment: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertAgreement) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [AlertAgreement]) -> [AlertAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertAgreements(_ store: any AlertAgreementStore, query: AlertAgreementQuery) -> [AlertAgreement] {
        return query.apply(store.list())
    }
}
