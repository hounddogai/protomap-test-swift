import Foundation

extension Kit.Clocks {
    /// Clock tells the current time in Unix seconds.
    public protocol Clock {
        func now() -> Int
    }

    /// SystemClock reads the wall clock.
    public final class SystemClock: Clock {
        public init() {
        }

        public func now() -> Int {
            return Int(Date().timeIntervalSince1970)
        }
    }

    /// FixedClock always tells the same time.
    public final class FixedClock: Clock {
        public var at: Int

        public init(at: Int) {
            self.at = at
        }

        public func now() -> Int {
            return at
        }
    }

    /// OffsetClock runs ahead of (or behind) another clock by a fixed number of seconds.
    public final class OffsetClock: Clock {
        public var base: SystemClock
        public var offset: Int

        public init(base: SystemClock, offset: Int) {
            self.base = base
            self.offset = offset
        }

        public func now() -> Int {
            return base.now() + offset
        }
    }

    /// StepClock advances by step seconds every time it is read.
    public final class StepClock: Clock {
        public var current: Int
        public var step: Int

        public init(current: Int, step: Int) {
            self.current = current
            self.step = step
        }

        public func now() -> Int {
            let at = current
            current = current + step
            return at
        }
    }

    public static func system() -> any Clock {
        return SystemClock()
    }
}
