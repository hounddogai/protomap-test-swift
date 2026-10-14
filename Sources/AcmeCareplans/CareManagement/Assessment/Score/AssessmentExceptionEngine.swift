import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment exception calculation.
    protocol AssessmentExceptionFactor {
        func describe() -> String
        func adjust(_ item: AssessmentException, value: Double) -> Double
    }

    final class TieredAssessmentExceptionAdjuster: AssessmentExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAssessmentExceptionAdjuster: AssessmentExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAssessmentExceptionAdjuster: AssessmentExceptionFactor {
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

        func adjust(_ item: AssessmentException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the assessment exception steps in order and keeps a trace of each.
    final class AssessmentExceptionEngine {
        var steps: [any AssessmentExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentException) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AssessmentException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentExceptionEngine(_ flags: Kit.Flags.Registry) -> AssessmentExceptionEngine {
        return AssessmentExceptionEngine(
            steps: [
                TieredAssessmentExceptionAdjuster(
                    bounds: [1537.0, 2517.0, 5853.0, 7137.0],
                    rates: [1.04, 1.14, 0.98, 0.81]
                ),
                PercentAssessmentExceptionAdjuster(percent: 14.7),
                FlaggedAssessmentExceptionAdjuster(flags: flags, flag: "assessment-exception-global", percent: -2.1),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 5500.5
        )
    }
}
