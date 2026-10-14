import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential agreements by code.
    protocol CredentialAgreementStore {
        func find(_ code: String) -> CredentialAgreement?
        func save(_ item: CredentialAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialAgreementStore: CredentialAgreementStore {
        var items: [String: CredentialAgreement]
        var order: [String]

        init(items: [String: CredentialAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialAgreement) {
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

        func list() -> [CredentialAgreement] {
            var out: [CredentialAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialAgreementStore() -> any CredentialAgreementStore {
        return MemoryCredentialAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialAgreementStore: CredentialAgreementStore {
        var inner: MemoryCredentialAgreementStore
        var cache: TTLCache<CredentialAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialAgreementStore, cache: TTLCache<CredentialAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialAgreement? {
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

        func save(_ item: CredentialAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialAgreement] {
            return inner.list()
        }
    }

    static func newCachedCredentialAgreementStore(_ inner: MemoryCredentialAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialAgreementStore {
        return CachedCredentialAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential agreements. Empty fields match all.
    final class CredentialAgreementQuery {
        var category: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialAgreement) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [CredentialAgreement]) -> [CredentialAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialAgreements(_ store: any CredentialAgreementStore, query: CredentialAgreementQuery) -> [CredentialAgreement] {
        return query.apply(store.list())
    }
}
