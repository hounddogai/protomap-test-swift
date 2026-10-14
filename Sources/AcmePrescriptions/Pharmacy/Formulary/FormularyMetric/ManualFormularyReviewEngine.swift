import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual formulary review calculation.
    protocol ManualFormularyReviewStep {
        func describe() -> String
        func adjust(_ item: ManualFormularyReview, value: Double) -> Double
    }

    final class NameManualFormularyReviewAdjuster: ManualFormularyReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualFormularyReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualFormularyReviewAdjuster: ManualFormularyReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualFormularyReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ManualFormularyReviewFloorValueOffsetAdjuster: ManualFormularyReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: ManualFormularyReview, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class PercentManualFormularyReviewAdjuster: ManualFormularyReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualFormularyReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualFormularyReviewAdjuster: ManualFormularyReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualFormularyReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual formulary review steps in order and keeps a trace of each.
    final class ManualFormularyReviewEngine {
        var steps: [any ManualFormularyReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFormularyReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualFormularyReview) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ManualFormularyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualFormularyReviewEngine() -> ManualFormularyReviewEngine {
        return ManualFormularyReviewEngine(
            steps: [
                NameManualFormularyReviewAdjuster(factors: ["south": 1.3, "retail": 1.04, "north": 1.0]),
                RoundingManualFormularyReviewAdjuster(step: 0.05),
                ManualFormularyReviewFloorValueOffsetAdjuster(weight: 0.93),
                PercentManualFormularyReviewAdjuster(percent: -13.6),
                TieredManualFormularyReviewAdjuster(bounds: [4342.0, 6828.0], rates: [0.86, 1.01]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 55634.1
        )
    }
}
