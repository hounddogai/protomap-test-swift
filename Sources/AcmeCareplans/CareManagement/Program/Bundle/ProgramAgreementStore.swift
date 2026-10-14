import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program agreements by code.
    protocol ProgramAgreementStore {
        func find(_ code: String) -> ProgramAgreement?
        func save(_ item: ProgramAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramAgreementStore: ProgramAgreementStore {
        var items: [String: ProgramAgreement]
        var order: [String]

        init(items: [String: ProgramAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramAgreement) {
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

        func list() -> [ProgramAgreement] {
            var out: [ProgramAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramAgreementStore() -> any ProgramAgreementStore {
        return MemoryProgramAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramAgreementStore: ProgramAgreementStore {
        var inner: MemoryProgramAgreementStore
        var cache: TTLCache<ProgramAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramAgreementStore, cache: TTLCache<ProgramAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramAgreement? {
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

        func save(_ item: ProgramAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramAgreement] {
            return inner.list()
        }
    }

    static func newCachedProgramAgreementStore(_ inner: MemoryProgramAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramAgreementStore {
        return CachedProgramAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program agreements. Empty fields match all.
    final class ProgramAgreementQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramAgreement) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramAgreement]) -> [ProgramAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramAgreements(_ store: any ProgramAgreementStore, query: ProgramAgreementQuery) -> [ProgramAgreement] {
        return query.apply(store.list())
    }
}
