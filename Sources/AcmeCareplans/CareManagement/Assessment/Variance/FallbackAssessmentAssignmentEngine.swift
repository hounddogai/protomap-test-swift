import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback assessment assignment calculation.
    protocol FallbackAssessmentAssignmentStep {
        func describe() -> String
        func adjust(_ item: FallbackAssessmentAssignment, value: Double) -> Double
    }

    final class TitleFallbackAssessmentAssignmentAdjuster: FallbackAssessmentAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackAssessmentAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackAssessmentAssignmentAdjuster: FallbackAssessmentAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAssessmentAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackAssessmentAssignmentCreatedAtOffsetAdjuster: FallbackAssessmentAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: FallbackAssessmentAssignment, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedFallbackAssessmentAssignmentAdjuster: FallbackAssessmentAssignmentStep {
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

        func adjust(_ item: FallbackAssessmentAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackAssessmentAssignmentAdjuster: FallbackAssessmentAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAssessmentAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback assessment assignment steps in order and keeps a trace of each.
    final class FallbackAssessmentAssignmentEngine {
        var steps: [any FallbackAssessmentAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAssessmentAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackAssessmentAssignment) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [FallbackAssessmentAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackAssessmentAssignmentEngine(_ flags: Kit.Flags.Registry) -> FallbackAssessmentAssignmentEngine {
        return FallbackAssessmentAssignmentEngine(
            steps: [
                TitleFallbackAssessmentAssignmentAdjuster(factors: ["retail": 0.71, "west": 1.23]),
                MinimumFallbackAssessmentAssignmentAdjuster(minimum: 40.1),
                FallbackAssessmentAssignmentCreatedAtOffsetAdjuster(weight: 0.04),
                FlaggedFallbackAssessmentAssignmentAdjuster(
                    flags: flags,
                    flag: "fallback-assessment-assignment-rolling",
                    percent: 3.2
                ),
                TieredFallbackAssessmentAssignmentAdjuster(bounds: [719.0, 1323.0, 9689.0], rates: [1.12, 0.99, 0.94]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 7067.3
        )
    }
}
