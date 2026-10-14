import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan review calculation.
    protocol AcuityPlanReviewModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanReview, value: Double) -> Double
    }

    final class MinimumAcuityPlanReviewAdjuster: AcuityPlanReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAcuityPlanReviewAdjuster: AcuityPlanReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAcuityPlanReviewAdjuster: AcuityPlanReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameAcuityPlanReviewAdjuster: AcuityPlanReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AcuityPlanReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAcuityPlanReviewAdjuster: AcuityPlanReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan review steps in order and keeps a trace of each.
    final class AcuityPlanReviewEngine {
        var steps: [any AcuityPlanReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanReview) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AcuityPlanReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanReviewEngine() -> AcuityPlanReviewEngine {
        return AcuityPlanReviewEngine(
            steps: [
                MinimumAcuityPlanReviewAdjuster(minimum: 16.5),
                TieredAcuityPlanReviewAdjuster(bounds: [2497.0, 6836.0, 9480.0], rates: [1.17, 0.88, 0.96]),
                PercentAcuityPlanReviewAdjuster(percent: -6.4),
                NameAcuityPlanReviewAdjuster(factors: ["online": 1.38, "east": 0.93, "central": 1.14]),
                CapAcuityPlanReviewAdjuster(cap: 11565.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 76563.5
        )
    }
}
