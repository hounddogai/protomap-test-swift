import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary handoff agreements by code.
    protocol PrimaryHandoffAgreementStore {
        func find(_ code: String) -> PrimaryHandoffAgreement?
        func save(_ item: PrimaryHandoffAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryHandoffAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryHandoffAgreementStore: PrimaryHandoffAgreementStore {
        var items: [String: PrimaryHandoffAgreement]
        var order: [String]

        init(items: [String: PrimaryHandoffAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryHandoffAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryHandoffAgreement) {
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

        func list() -> [PrimaryHandoffAgreement] {
            var out: [PrimaryHandoffAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryHandoffAgreementStore() -> any PrimaryHandoffAgreementStore {
        return MemoryPrimaryHandoffAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryHandoffAgreementStore: PrimaryHandoffAgreementStore {
        var inner: MemoryPrimaryHandoffAgreementStore
        var cache: TTLCache<PrimaryHandoffAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryHandoffAgreementStore, cache: TTLCache<PrimaryHandoffAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryHandoffAgreement? {
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

        func save(_ item: PrimaryHandoffAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryHandoffAgreement] {
            return inner.list()
        }
    }

    static func newCachedPrimaryHandoffAgreementStore(_ inner: MemoryPrimaryHandoffAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryHandoffAgreementStore {
        return CachedPrimaryHandoffAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary handoff agreements. Empty fields match all.
    final class PrimaryHandoffAgreementQuery {
        var channel: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minPriority: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryHandoffAgreement) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryHandoffAgreement]) -> [PrimaryHandoffAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryHandoffAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryHandoffAgreements(_ store: any PrimaryHandoffAgreementStore, query: PrimaryHandoffAgreementQuery) -> [PrimaryHandoffAgreement] {
        return query.apply(store.list())
    }
}
