import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score profiles by code.
    protocol RiskScoreProfileStore {
        func find(_ code: String) -> RiskScoreProfile?
        func save(_ item: RiskScoreProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreProfileStore: RiskScoreProfileStore {
        var items: [String: RiskScoreProfile]
        var order: [String]

        init(items: [String: RiskScoreProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreProfile) {
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

        func list() -> [RiskScoreProfile] {
            var out: [RiskScoreProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreProfileStore() -> any RiskScoreProfileStore {
        return MemoryRiskScoreProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreProfileStore: RiskScoreProfileStore {
        var inner: MemoryRiskScoreProfileStore
        var cache: TTLCache<RiskScoreProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreProfileStore, cache: TTLCache<RiskScoreProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreProfile? {
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

        func save(_ item: RiskScoreProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreProfile] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreProfileStore(_ inner: MemoryRiskScoreProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreProfileStore {
        return CachedRiskScoreProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score profiles. Empty fields match all.
    final class RiskScoreProfileQuery {
        var segment: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVersion: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [RiskScoreProfile]) -> [RiskScoreProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreProfiles(_ store: any RiskScoreProfileStore, query: RiskScoreProfileQuery) -> [RiskScoreProfile] {
        return query.apply(store.list())
    }
}
