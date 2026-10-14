import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient slot digest calculation.
    protocol LenientSlotDigestFactor {
        func describe() -> String
        func adjust(_ item: LenientSlotDigest, value: Double) -> Double
    }

    final class CapLenientSlotDigestAdjuster: LenientSlotDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientSlotDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientSlotDigestAdjuster: LenientSlotDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientSlotDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientSlotDigestAdjuster: LenientSlotDigestFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: LenientSlotDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientSlotDigestAdjuster: LenientSlotDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSlotDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient slot digest steps in order and keeps a trace of each.
    final class LenientSlotDigestEngine {
        var steps: [any LenientSlotDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSlotDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientSlotDigest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSlotDigestFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientSlotDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientSlotDigestEngine(_ flags: Kit.Flags.Registry) -> LenientSlotDigestEngine {
        return LenientSlotDigestEngine(
            steps: [
                CapLenientSlotDigestAdjuster(cap: 27379.0),
                PercentLenientSlotDigestAdjuster(percent: -2.3),
                FlaggedLenientSlotDigestAdjuster(flags: flags, flag: "lenient-slot-digest-fallback", percent: 2.1),
                RoundingLenientSlotDigestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 7054.8
        )
    }
}
