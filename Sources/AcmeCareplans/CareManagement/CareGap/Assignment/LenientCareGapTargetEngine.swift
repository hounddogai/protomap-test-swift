import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient care gap target calculation.
    protocol LenientCareGapTargetStep {
        func describe() -> String
        func adjust(_ item: LenientCareGapTarget, value: Double) -> Double
    }

    final class TieredLenientCareGapTargetAdjuster: LenientCareGapTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCareGapTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientCareGapTargetAdjuster: LenientCareGapTargetStep {
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

        func adjust(_ item: LenientCareGapTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientCareGapTargetAdjuster: LenientCareGapTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCareGapTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientCareGapTargetAdjuster: LenientCareGapTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareGapTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelLenientCareGapTargetAdjuster: LenientCareGapTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientCareGapTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient care gap target steps in order and keeps a trace of each.
    final class LenientCareGapTargetEngine {
        var steps: [any LenientCareGapTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareGapTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCareGapTarget) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCareGapTargetStep = steps[index]
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

        func evaluateAll(_ items: [LenientCareGapTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCareGapTargetEngine(_ flags: Kit.Flags.Registry) -> LenientCareGapTargetEngine {
        return LenientCareGapTargetEngine(
            steps: [
                TieredLenientCareGapTargetAdjuster(bounds: [1463.0, 4037.0, 4275.0], rates: [1.02, 0.94, 1.12]),
                FlaggedLenientCareGapTargetAdjuster(
                    flags: flags,
                    flag: "lenient-care-gap-target-batched",
                    percent: 5.0
                ),
                RoundingLenientCareGapTargetAdjuster(step: 0.25),
                MinimumLenientCareGapTargetAdjuster(minimum: 45.2),
                LabelLenientCareGapTargetAdjuster(factors: ["central": 1.34, "online": 0.74]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 98781.6
        )
    }
}
