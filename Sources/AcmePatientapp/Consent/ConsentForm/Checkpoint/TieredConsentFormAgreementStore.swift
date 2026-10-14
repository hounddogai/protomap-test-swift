import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered consent form agreements by code.
    protocol TieredConsentFormAgreementStore {
        func find(_ code: String) -> TieredConsentFormAgreement?
        func save(_ item: TieredConsentFormAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [TieredConsentFormAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredConsentFormAgreementStore: TieredConsentFormAgreementStore {
        var items: [String: TieredConsentFormAgreement]
        var order: [String]

        init(items: [String: TieredConsentFormAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredConsentFormAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredConsentFormAgreement) {
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

        func list() -> [TieredConsentFormAgreement] {
            var out: [TieredConsentFormAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredConsentFormAgreementStore() -> any TieredConsentFormAgreementStore {
        return MemoryTieredConsentFormAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredConsentFormAgreementStore: TieredConsentFormAgreementStore {
        var inner: MemoryTieredConsentFormAgreementStore
        var cache: TTLCache<TieredConsentFormAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredConsentFormAgreementStore, cache: TTLCache<TieredConsentFormAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredConsentFormAgreement? {
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

        func save(_ item: TieredConsentFormAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredConsentFormAgreement] {
            return inner.list()
        }
    }

    static func newCachedTieredConsentFormAgreementStore(_ inner: MemoryTieredConsentFormAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredConsentFormAgreementStore {
        return CachedTieredConsentFormAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered consent form agreements. Empty fields match all.
    final class TieredConsentFormAgreementQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredConsentFormAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredConsentFormAgreement]) -> [TieredConsentFormAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredConsentFormAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredConsentFormAgreements(_ store: any TieredConsentFormAgreementStore, query: TieredConsentFormAgreementQuery) -> [TieredConsentFormAgreement] {
        return query.apply(store.list())
    }
}
