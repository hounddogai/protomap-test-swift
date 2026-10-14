import Foundation

extension Kit.Retry {
    /// Backoff says how many milliseconds to wait before the next attempt.
    public protocol Backoff {
        func delay(_ attempt: Int) -> Int
    }

    public final class ConstantBackoff: Backoff {
        public var millis: Int

        public init(millis: Int) {
            self.millis = millis
        }

        public func delay(_ attempt: Int) -> Int {
            return millis
        }
    }

    public final class LinearBackoff: Backoff {
        public var step: Int
        public var cap: Int

        public init(step: Int, cap: Int) {
            self.step = step
            self.cap = cap
        }

        public func delay(_ attempt: Int) -> Int {
            return Swift.min(step * (attempt + 1), cap)
        }
    }

    public final class ExponentialBackoff: Backoff {
        public var base: Int
        public var factor: Double
        public var cap: Int

        public init(base: Int, factor: Double, cap: Int) {
            self.base = base
            self.factor = factor
            self.cap = cap
        }

        public func delay(_ attempt: Int) -> Int {
            var delay = Double(base)
            for _ in 0..<attempt {
                delay = delay * factor
            }
            return Swift.min(Int(delay), cap)
        }
    }

    /// JitterBackoff spreads another backoff's delays by a stable pseudo-random amount.
    public final class JitterBackoff: Backoff {
        public var inner: any Backoff
        public var spread: Int
        public var salt: String

        public init(inner: any Backoff, spread: Int, salt: String) {
            self.inner = inner
            self.spread = spread
            self.salt = salt
        }

        public func delay(_ attempt: Int) -> Int {
            let base = inner.delay(attempt)
            if spread <= 0 {
                return base
            }
            let noise = Kit.stableHash("\(salt):\(attempt)") % spread
            return base + noise
        }
    }

    /// Policy retries an operation up to attempts times.
    public final class Policy {
        public var attempts: Int
        public var backoff: any Backoff

        public init(attempts: Int, backoff: any Backoff) {
            self.attempts = attempts
            self.backoff = backoff
        }

        /// Calls op until it succeeds and returns how many attempts it took.
        public func run(_ op: (Int) -> Bool) throws -> Int {
            var waited = 0
            for attempt in 0..<attempts {
                if op(attempt) {
                    return attempt + 1
                }
                waited += backoff.delay(attempt)
            }
            throw Kit.Failure("gave up after \(attempts) attempts and \(waited) ms")
        }

        public func totalDelay() -> Int {
            var total = 0
            for attempt in 0..<attempts {
                total += backoff.delay(attempt)
            }
            return total
        }
    }

    public static func defaultPolicy(_ salt: String) -> Policy {
        return Policy(
            attempts: 5,
            backoff: JitterBackoff(inner: ExponentialBackoff(base: 100, factor: 2.0, cap: 5000), spread: 50, salt: salt)
        )
    }
}
