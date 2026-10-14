import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding snapshot calculation.
    protocol RoundingSnapshotModifier {
        func describe() -> String
        func adjust(_ item: RoundingSnapshot, value: Double) -> Double
    }

    final class LocaleRoundingSnapshotAdjuster: RoundingSnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RoundingSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRoundingSnapshotAdjuster: RoundingSnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRoundingSnapshotAdjuster: RoundingSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRoundingSnapshotAdjuster: RoundingSnapshotModifier {
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

        func adjust(_ item: RoundingSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRoundingSnapshotAdjuster: RoundingSnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRoundingSnapshotAdjuster: RoundingSnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rounding snapshot steps in order and keeps a trace of each.
    final class RoundingSnapshotEngine {
        var steps: [any RoundingSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RoundingSnapshot) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [RoundingSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRoundingSnapshotEngine(_ flags: Kit.Flags.Registry) -> RoundingSnapshotEngine {
        return RoundingSnapshotEngine(
            steps: [
                LocaleRoundingSnapshotAdjuster(factors: ["north": 1.23, "west": 0.84, "south": 1.22]),
                PercentRoundingSnapshotAdjuster(percent: 8.0),
                RoundingRoundingSnapshotAdjuster(step: 5.0),
                FlaggedRoundingSnapshotAdjuster(flags: flags, flag: "rounding-snapshot-primary", percent: -3.4),
                MinimumRoundingSnapshotAdjuster(minimum: 24.6),
                CapRoundingSnapshotAdjuster(cap: 20213.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 16945.4
        )
    }
}
