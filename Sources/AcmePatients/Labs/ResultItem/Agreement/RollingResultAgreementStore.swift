import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling result agreements by code.
    protocol RollingResultAgreementStore {
        func find(_ code: String) -> RollingResultAgreement?
        func save(_ item: RollingResultAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RollingResultAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingResultAgreementStore: RollingResultAgreementStore {
        var items: [String: RollingResultAgreement]
        var order: [String]

        init(items: [String: RollingResultAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingResultAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingResultAgreement) {
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

        func list() -> [RollingResultAgreement] {
            var out: [RollingResultAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingResultAgreementStore() -> any RollingResultAgreementStore {
        return MemoryRollingResultAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingResultAgreementStore: RollingResultAgreementStore {
        var inner: MemoryRollingResultAgreementStore
        var cache: TTLCache<RollingResultAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingResultAgreementStore, cache: TTLCache<RollingResultAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingResultAgreement? {
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

        func save(_ item: RollingResultAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingResultAgreement] {
            return inner.list()
        }
    }

    static func newCachedRollingResultAgreementStore(_ inner: MemoryRollingResultAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingResultAgreementStore {
        return CachedRollingResultAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling result agreements. Empty fields match all.
    final class RollingResultAgreementQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingResultAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RollingResultAgreement]) -> [RollingResultAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingResultAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingResultAgreements(_ store: any RollingResultAgreementStore, query: RollingResultAgreementQuery) -> [RollingResultAgreement] {
        return query.apply(store.list())
    }
}
