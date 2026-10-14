import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding request calculation.
    protocol RoundingRequestModifier {
        func describe() -> String
        func adjust(_ item: RoundingRequest, value: Double) -> Double
    }

    final class PercentRoundingRequestAdjuster: RoundingRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRoundingRequestAdjuster: RoundingRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RoundingRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRoundingRequestAdjuster: RoundingRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRoundingRequestAdjuster: RoundingRequestModifier {
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

        func adjust(_ item: RoundingRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rounding request steps in order and keeps a trace of each.
    final class RoundingRequestEngine {
        var steps: [any RoundingRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingRequest) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingRequestModifier = steps[index]
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

        func evaluateAll(_ items: [RoundingRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingRequestEngine(_ flags: Kit.Flags.Registry) -> RoundingRequestEngine {
        return RoundingRequestEngine(
            steps: [
                PercentRoundingRequestAdjuster(percent: -3.4),
                LabelRoundingRequestAdjuster(factors: ["west": 1.17, "east": 1.35, "online": 0.92]),
                RoundingRoundingRequestAdjuster(step: 0.25),
                FlaggedRoundingRequestAdjuster(flags: flags, flag: "rounding-request-seasonal", percent: 7.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 50520.6
        )
    }
}
