import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy assessment estimate calculation.
    protocol LegacyAssessmentEstimateFactor {
        func describe() -> String
        func adjust(_ item: LegacyAssessmentEstimate, value: Double) -> Double
    }

    final class PercentLegacyAssessmentEstimateAdjuster: LegacyAssessmentEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAssessmentEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityLegacyAssessmentEstimateAdjuster: LegacyAssessmentEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: LegacyAssessmentEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLegacyAssessmentEstimateAdjuster: LegacyAssessmentEstimateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAssessmentEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLegacyAssessmentEstimateAdjuster: LegacyAssessmentEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAssessmentEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy assessment estimate steps in order and keeps a trace of each.
    final class LegacyAssessmentEstimateEngine {
        var steps: [any LegacyAssessmentEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAssessmentEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyAssessmentEstimate) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [LegacyAssessmentEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyAssessmentEstimateEngine() -> LegacyAssessmentEstimateEngine {
        return LegacyAssessmentEstimateEngine(
            steps: [
                PercentLegacyAssessmentEstimateAdjuster(percent: -11.4),
                FacilityLegacyAssessmentEstimateAdjuster(factors: ["north": 1.18, "online": 1.05, "south": 1.25]),
                CapLegacyAssessmentEstimateAdjuster(cap: 14522.0),
                RoundingLegacyAssessmentEstimateAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 97542.6
        )
    }
}
