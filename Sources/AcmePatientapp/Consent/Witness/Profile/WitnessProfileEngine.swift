import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness profile calculation.
    protocol WitnessProfileModifier {
        func describe() -> String
        func adjust(_ item: WitnessProfile, value: Double) -> Double
    }

    final class RoundingWitnessProfileAdjuster: WitnessProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentWitnessProfileAdjuster: WitnessProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: WitnessProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWitnessProfileAdjuster: WitnessProfileModifier {
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

        func adjust(_ item: WitnessProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWitnessProfileAdjuster: WitnessProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness profile steps in order and keeps a trace of each.
    final class WitnessProfileEngine {
        var steps: [any WitnessProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessProfile) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessProfileModifier = steps[index]
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

        func evaluateAll(_ items: [WitnessProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessProfileEngine(_ flags: Kit.Flags.Registry) -> WitnessProfileEngine {
        return WitnessProfileEngine(
            steps: [
                RoundingWitnessProfileAdjuster(step: 0.05),
                SegmentWitnessProfileAdjuster(factors: ["online": 1.09]),
                FlaggedWitnessProfileAdjuster(flags: flags, flag: "witness-profile-strict", percent: -1.6),
                PercentWitnessProfileAdjuster(percent: -13.2),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 50965.6
        )
    }
}
