import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient rounding profile calculation.
    protocol LenientRoundingProfileStep {
        func describe() -> String
        func adjust(_ item: LenientRoundingProfile, value: Double) -> Double
    }

    final class LenientRoundingProfileThresholdOffsetAdjuster: LenientRoundingProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LenientRoundingProfile, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredLenientRoundingProfileAdjuster: LenientRoundingProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRoundingProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientRoundingProfileAdjuster: LenientRoundingProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRoundingProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient rounding profile steps in order and keeps a trace of each.
    final class LenientRoundingProfileEngine {
        var steps: [any LenientRoundingProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRoundingProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientRoundingProfile) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientRoundingProfileStep = steps[index]
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

        func evaluateAll(_ items: [LenientRoundingProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientRoundingProfileEngine() -> LenientRoundingProfileEngine {
        return LenientRoundingProfileEngine(
            steps: [
                LenientRoundingProfileThresholdOffsetAdjuster(weight: 1.63),
                TieredLenientRoundingProfileAdjuster(bounds: [2304.0, 2493.0], rates: [0.93, 1.18]),
                MinimumLenientRoundingProfileAdjuster(minimum: 43.2),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 82289.8
        )
    }
}
