import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment bundle calculation.
    protocol AssessmentBundleModifier {
        func describe() -> String
        func adjust(_ item: AssessmentBundle, value: Double) -> Double
    }

    final class CapAssessmentBundleAdjuster: AssessmentBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAssessmentBundleAdjuster: AssessmentBundleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAssessmentBundleAdjuster: AssessmentBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAssessmentBundleAdjuster: AssessmentBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AssessmentBundleRevisionOffsetAdjuster: AssessmentBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: AssessmentBundle, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredAssessmentBundleAdjuster: AssessmentBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the assessment bundle steps in order and keeps a trace of each.
    final class AssessmentBundleEngine {
        var steps: [any AssessmentBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AssessmentBundle) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentBundleModifier = steps[index]
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

        func evaluateAll(_ items: [AssessmentBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAssessmentBundleEngine() -> AssessmentBundleEngine {
        return AssessmentBundleEngine(
            steps: [
                CapAssessmentBundleAdjuster(cap: 674.0),
                RoundingAssessmentBundleAdjuster(step: 1.0),
                PercentAssessmentBundleAdjuster(percent: -10.1),
                MinimumAssessmentBundleAdjuster(minimum: 47.4),
                AssessmentBundleRevisionOffsetAdjuster(weight: 0.62),
                TieredAssessmentBundleAdjuster(
                    bounds: [2192.0, 3119.0, 4101.0, 7857.0],
                    rates: [1.03, 0.99, 0.86, 0.92]
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 71181.3
        )
    }
}
