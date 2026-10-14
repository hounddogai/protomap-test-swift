import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment variance calculation.
    protocol AssessmentVarianceModifier {
        func describe() -> String
        func adjust(_ item: AssessmentVariance, value: Double) -> Double
    }

    final class CapAssessmentVarianceAdjuster: AssessmentVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAssessmentVarianceAdjuster: AssessmentVarianceModifier {
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

        func adjust(_ item: AssessmentVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionAssessmentVarianceAdjuster: AssessmentVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: AssessmentVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAssessmentVarianceAdjuster: AssessmentVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAssessmentVarianceAdjuster: AssessmentVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AssessmentVarianceGraceDaysOffsetAdjuster: AssessmentVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: AssessmentVariance, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the assessment variance steps in order and keeps a trace of each.
    final class AssessmentVarianceEngine {
        var steps: [any AssessmentVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AssessmentVariance) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [AssessmentVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAssessmentVarianceEngine(_ flags: Kit.Flags.Registry) -> AssessmentVarianceEngine {
        return AssessmentVarianceEngine(
            steps: [
                CapAssessmentVarianceAdjuster(cap: 37745.0),
                FlaggedAssessmentVarianceAdjuster(flags: flags, flag: "assessment-variance-tiered", percent: 8.8),
                RegionAssessmentVarianceAdjuster(factors: ["retail": 1.02]),
                RoundingAssessmentVarianceAdjuster(step: 5.0),
                TieredAssessmentVarianceAdjuster(bounds: [4121.0, 7256.0], rates: [1.04, 1.16]),
                AssessmentVarianceGraceDaysOffsetAdjuster(weight: 0.18),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 65716.3
        )
    }
}
