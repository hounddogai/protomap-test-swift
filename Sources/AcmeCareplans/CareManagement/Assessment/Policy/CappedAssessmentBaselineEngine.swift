import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped assessment baseline calculation.
    protocol CappedAssessmentBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: CappedAssessmentBaseline, value: Double) -> Double
    }

    final class LabelCappedAssessmentBaselineAdjuster: CappedAssessmentBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedAssessmentBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedAssessmentBaselineAdjuster: CappedAssessmentBaselineAdjuster {
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

        func adjust(_ item: CappedAssessmentBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedAssessmentBaselineAdjuster: CappedAssessmentBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedAssessmentBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCappedAssessmentBaselineAdjuster: CappedAssessmentBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedAssessmentBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedAssessmentBaselineExpiresAtOffsetAdjuster: CappedAssessmentBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: CappedAssessmentBaseline, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the capped assessment baseline steps in order and keeps a trace of each.
    final class CappedAssessmentBaselineEngine {
        var steps: [any CappedAssessmentBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedAssessmentBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedAssessmentBaseline) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [CappedAssessmentBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedAssessmentBaselineEngine(_ flags: Kit.Flags.Registry) -> CappedAssessmentBaselineEngine {
        return CappedAssessmentBaselineEngine(
            steps: [
                LabelCappedAssessmentBaselineAdjuster(factors: ["online": 1.38, "south": 0.89, "north": 1.35]),
                FlaggedCappedAssessmentBaselineAdjuster(
                    flags: flags,
                    flag: "capped-assessment-baseline-adaptive",
                    percent: 6.4
                ),
                TieredCappedAssessmentBaselineAdjuster(bounds: [4404.0, 9285.0, 9794.0], rates: [1.03, 1.06, 0.87]),
                MinimumCappedAssessmentBaselineAdjuster(minimum: 17.2),
                CappedAssessmentBaselineExpiresAtOffsetAdjuster(weight: 0.23),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 75491.6
        )
    }
}
