import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment policy calculation.
    protocol AssessmentPolicyFactor {
        func describe() -> String
        func adjust(_ item: AssessmentPolicy, value: Double) -> Double
    }

    final class RoundingAssessmentPolicyAdjuster: AssessmentPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAssessmentPolicyAdjuster: AssessmentPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAssessmentPolicyAdjuster: AssessmentPolicyFactor {
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

        func adjust(_ item: AssessmentPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AssessmentPolicyWindowDaysOffsetAdjuster: AssessmentPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AssessmentPolicy, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the assessment policy steps in order and keeps a trace of each.
    final class AssessmentPolicyEngine {
        var steps: [any AssessmentPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AssessmentPolicy) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [AssessmentPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAssessmentPolicyEngine(_ flags: Kit.Flags.Registry) -> AssessmentPolicyEngine {
        return AssessmentPolicyEngine(
            steps: [
                RoundingAssessmentPolicyAdjuster(step: 0.1),
                TieredAssessmentPolicyAdjuster(
                    bounds: [205.0, 3395.0, 5492.0, 6344.0],
                    rates: [0.9, 0.89, 0.89, 0.89]
                ),
                FlaggedAssessmentPolicyAdjuster(flags: flags, flag: "assessment-policy-capped", percent: -9.2),
                AssessmentPolicyWindowDaysOffsetAdjuster(weight: 0.94),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 51806.6
        )
    }
}
