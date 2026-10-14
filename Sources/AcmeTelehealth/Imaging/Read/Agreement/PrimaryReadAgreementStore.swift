import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary read agreements by code.
    protocol PrimaryReadAgreementStore {
        func find(_ code: String) -> PrimaryReadAgreement?
        func save(_ item: PrimaryReadAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReadAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReadAgreementStore: PrimaryReadAgreementStore {
        var items: [String: PrimaryReadAgreement]
        var order: [String]

        init(items: [String: PrimaryReadAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReadAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReadAgreement) {
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

        func list() -> [PrimaryReadAgreement] {
            var out: [PrimaryReadAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReadAgreementStore() -> any PrimaryReadAgreementStore {
        return MemoryPrimaryReadAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReadAgreementStore: PrimaryReadAgreementStore {
        var inner: MemoryPrimaryReadAgreementStore
        var cache: TTLCache<PrimaryReadAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReadAgreementStore, cache: TTLCache<PrimaryReadAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReadAgreement? {
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

        func save(_ item: PrimaryReadAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReadAgreement] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReadAgreementStore(_ inner: MemoryPrimaryReadAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReadAgreementStore {
        return CachedPrimaryReadAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary read agreements. Empty fields match all.
    final class PrimaryReadAgreementQuery {
        var source: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVersion: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReadAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryReadAgreement]) -> [PrimaryReadAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReadAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReadAgreements(_ store: any PrimaryReadAgreementStore, query: PrimaryReadAgreementQuery) -> [PrimaryReadAgreement] {
        return query.apply(store.list())
    }
}
