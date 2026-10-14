import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps scheduled dispense agreements by code.
    protocol ScheduledDispenseAgreementStore {
        func find(_ code: String) -> ScheduledDispenseAgreement?
        func save(_ item: ScheduledDispenseAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledDispenseAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledDispenseAgreementStore: ScheduledDispenseAgreementStore {
        var items: [String: ScheduledDispenseAgreement]
        var order: [String]

        init(items: [String: ScheduledDispenseAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledDispenseAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledDispenseAgreement) {
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

        func list() -> [ScheduledDispenseAgreement] {
            var out: [ScheduledDispenseAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledDispenseAgreementStore() -> any ScheduledDispenseAgreementStore {
        return MemoryScheduledDispenseAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledDispenseAgreementStore: ScheduledDispenseAgreementStore {
        var inner: MemoryScheduledDispenseAgreementStore
        var cache: TTLCache<ScheduledDispenseAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledDispenseAgreementStore, cache: TTLCache<ScheduledDispenseAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledDispenseAgreement? {
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

        func save(_ item: ScheduledDispenseAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledDispenseAgreement] {
            return inner.list()
        }
    }

    static func newCachedScheduledDispenseAgreementStore(_ inner: MemoryScheduledDispenseAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledDispenseAgreementStore {
        return CachedScheduledDispenseAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled dispense agreements. Empty fields match all.
    final class ScheduledDispenseAgreementQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledDispenseAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledDispenseAgreement]) -> [ScheduledDispenseAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledDispenseAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledDispenseAgreements(_ store: any ScheduledDispenseAgreementStore, query: ScheduledDispenseAgreementQuery) -> [ScheduledDispenseAgreement] {
        return query.apply(store.list())
    }
}
