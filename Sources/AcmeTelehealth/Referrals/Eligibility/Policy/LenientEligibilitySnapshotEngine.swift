import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient eligibility snapshot calculation.
    protocol LenientEligibilitySnapshotModifier {
        func describe() -> String
        func adjust(_ item: LenientEligibilitySnapshot, value: Double) -> Double
    }

    final class RoundingLenientEligibilitySnapshotAdjuster: LenientEligibilitySnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientEligibilitySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientEligibilitySnapshotAdjuster: LenientEligibilitySnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientEligibilitySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LenientEligibilitySnapshotDiscountOffsetAdjuster: LenientEligibilitySnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LenientEligibilitySnapshot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class FlaggedLenientEligibilitySnapshotAdjuster: LenientEligibilitySnapshotModifier {
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

        func adjust(_ item: LenientEligibilitySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientEligibilitySnapshotAdjuster: LenientEligibilitySnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientEligibilitySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient eligibility snapshot steps in order and keeps a trace of each.
    final class LenientEligibilitySnapshotEngine {
        var steps: [any LenientEligibilitySnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientEligibilitySnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientEligibilitySnapshot) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientEligibilitySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientEligibilitySnapshotEngine(_ flags: Kit.Flags.Registry) -> LenientEligibilitySnapshotEngine {
        return LenientEligibilitySnapshotEngine(
            steps: [
                RoundingLenientEligibilitySnapshotAdjuster(step: 0.05),
                MinimumLenientEligibilitySnapshotAdjuster(minimum: 11.6),
                LenientEligibilitySnapshotDiscountOffsetAdjuster(weight: 1.89),
                FlaggedLenientEligibilitySnapshotAdjuster(
                    flags: flags,
                    flag: "lenient-eligibility-snapshot-primary",
                    percent: 4.5
                ),
                CapLenientEligibilitySnapshotAdjuster(cap: 22287.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 89871.5
        )
    }
}
