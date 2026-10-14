import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment score calculation.
    protocol AssessmentScoreAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentScore, value: Double) -> Double
    }

    final class RoundingAssessmentScoreAdjuster: AssessmentScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleAssessmentScoreAdjuster: AssessmentScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AssessmentScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAssessmentScoreAdjuster: AssessmentScoreAdjuster {
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

        func adjust(_ item: AssessmentScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAssessmentScoreAdjuster: AssessmentScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAssessmentScoreAdjuster: AssessmentScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAssessmentScoreAdjuster: AssessmentScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the assessment score steps in order and keeps a trace of each.
    final class AssessmentScoreEngine {
        var steps: [any AssessmentScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentScore) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [AssessmentScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentScoreEngine(_ flags: Kit.Flags.Registry) -> AssessmentScoreEngine {
        return AssessmentScoreEngine(
            steps: [
                RoundingAssessmentScoreAdjuster(step: 5.0),
                TitleAssessmentScoreAdjuster(factors: ["online": 0.85]),
                FlaggedAssessmentScoreAdjuster(flags: flags, flag: "assessment-score-batched", percent: -5.8),
                MinimumAssessmentScoreAdjuster(minimum: 35.2),
                TieredAssessmentScoreAdjuster(
                    bounds: [806.0, 1097.0, 1627.0, 7832.0],
                    rates: [1.07, 1.14, 1.11, 0.81]
                ),
                CapAssessmentScoreAdjuster(cap: 48201.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 80644.5
        )
    }
}
