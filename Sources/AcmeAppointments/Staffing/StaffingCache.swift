import AcmePlatform
import Foundation

// The area's record cache: up to a capacity of values, each for a time to live, oldest out first.
extension Staffing {
    /// TtlCache keeps up to capacity values for ttl seconds each, evicting the oldest first.
    final class TTLCache<V> {
        var entries: [String: V]
        var expires: [String: Int]
        var order: [String]
        var capacity: Int
        var ttl: Int
        var clock: any Kit.Clocks.Clock

        init(entries: [String: V], expires: [String: Int], order: [String], capacity: Int, ttl: Int, clock: any Kit.Clocks.Clock) {
            self.entries = entries
            self.expires = expires
            self.order = order
            self.capacity = capacity
            self.ttl = ttl
            self.clock = clock
        }

        func getValue(_ key: String) -> V? {
            guard let deadline = expires[key] else {
                return nil
            }
            if clock.now() > deadline {
                entries.removeValue(forKey: key)
                expires.removeValue(forKey: key)
                return nil
            }
            guard let value = entries[key] else {
                return nil
            }
            return value
        }

        func put(_ key: String, value: V) {
            if !(entries[key] != nil) {
                order.append(key)
            }
            entries[key] = value
            expires[key] = clock.now() + ttl
            while order.count > capacity && (order.count > 0) {
                let oldest = order[0]
                order = Array(order.dropFirst(1))
                entries.removeValue(forKey: oldest)
                expires.removeValue(forKey: oldest)
            }
        }

        func size() -> Int {
            return entries.count
        }

        func purgeExpired() -> Int {
            let now = clock.now()
            var kept: [String] = []
            var removed = 0
            for key in order {
                let deadline = expires[key, default: 0]
                if now > deadline {
                    entries.removeValue(forKey: key)
                    expires.removeValue(forKey: key)
                    removed += 1
                    continue
                }
                kept.append(key)
            }
            order = kept
            return removed
        }
    }

    static func newTTLCache<V>(_ capacity: Int, ttl: Int, clock: any Kit.Clocks.Clock) -> TTLCache<V> {
        return TTLCache<V>(entries: [:], expires: [:], order: [], capacity: capacity, ttl: ttl, clock: clock)
    }
}
