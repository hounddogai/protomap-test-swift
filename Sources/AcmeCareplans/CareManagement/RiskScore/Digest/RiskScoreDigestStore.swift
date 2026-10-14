import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score digests by code.
    protocol RiskScoreDigestStore {
        func find(_ code: String) -> RiskScoreDigest?
        func save(_ item: RiskScoreDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreDigestStore: RiskScoreDigestStore {
        var items: [String: RiskScoreDigest]
        var order: [String]

        init(items: [String: RiskScoreDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreDigest) {
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

        func list() -> [RiskScoreDigest] {
            var out: [RiskScoreDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreDigestStore() -> any RiskScoreDigestStore {
        return MemoryRiskScoreDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreDigestStore: RiskScoreDigestStore {
        var inner: MemoryRiskScoreDigestStore
        var cache: TTLCache<RiskScoreDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreDigestStore, cache: TTLCache<RiskScoreDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreDigest? {
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

        func save(_ item: RiskScoreDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreDigest] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreDigestStore(_ inner: MemoryRiskScoreDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreDigestStore {
        return CachedRiskScoreDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score digests. Empty fields match all.
    final class RiskScoreDigestQuery {
        var locale: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreDigest]) -> [RiskScoreDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreDigests(_ store: any RiskScoreDigestStore, query: RiskScoreDigestQuery) -> [RiskScoreDigest] {
        return query.apply(store.list())
    }
}
