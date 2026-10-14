import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling disclosure agreements by code.
    protocol RollingDisclosureAgreementStore {
        func find(_ code: String) -> RollingDisclosureAgreement?
        func save(_ item: RollingDisclosureAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDisclosureAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDisclosureAgreementStore: RollingDisclosureAgreementStore {
        var items: [String: RollingDisclosureAgreement]
        var order: [String]

        init(items: [String: RollingDisclosureAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDisclosureAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDisclosureAgreement) {
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

        func list() -> [RollingDisclosureAgreement] {
            var out: [RollingDisclosureAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDisclosureAgreementStore() -> any RollingDisclosureAgreementStore {
        return MemoryRollingDisclosureAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDisclosureAgreementStore: RollingDisclosureAgreementStore {
        var inner: MemoryRollingDisclosureAgreementStore
        var cache: TTLCache<RollingDisclosureAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDisclosureAgreementStore, cache: TTLCache<RollingDisclosureAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDisclosureAgreement? {
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

        func save(_ item: RollingDisclosureAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDisclosureAgreement] {
            return inner.list()
        }
    }

    static func newCachedRollingDisclosureAgreementStore(_ inner: MemoryRollingDisclosureAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDisclosureAgreementStore {
        return CachedRollingDisclosureAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling disclosure agreements. Empty fields match all.
    final class RollingDisclosureAgreementQuery {
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

        func matches(_ item: RollingDisclosureAgreement) -> Bool {
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

        func apply(_ items: [RollingDisclosureAgreement]) -> [RollingDisclosureAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDisclosureAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDisclosureAgreements(_ store: any RollingDisclosureAgreementStore, query: RollingDisclosureAgreementQuery) -> [RollingDisclosureAgreement] {
        return query.apply(store.list())
    }
}
