import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual modality estimate calculation.
    protocol ManualModalityEstimateModifier {
        func describe() -> String
        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double
    }

    final class CapManualModalityEstimateAdjuster: ManualModalityEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualModalityEstimateAdjuster: ManualModalityEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualModalityEstimateAdjuster: ManualModalityEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualModalityEstimateAdjuster: ManualModalityEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualModalityEstimateLimitOffsetAdjuster: ManualModalityEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumManualModalityEstimateAdjuster: ManualModalityEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualModalityEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual modality estimate steps in order and keeps a trace of each.
    final class ManualModalityEstimateEngine {
        var steps: [any ManualModalityEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualModalityEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualModalityEstimate) -> Double {
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

        func evaluateAll(_ items: [ManualModalityEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualModalityEstimateEngine() -> ManualModalityEstimateEngine {
        return ManualModalityEstimateEngine(
            steps: [
                CapManualModalityEstimateAdjuster(cap: 18059.0),
                PercentManualModalityEstimateAdjuster(percent: 16.4),
                RoundingManualModalityEstimateAdjuster(step: 0.1),
                TieredManualModalityEstimateAdjuster(
                    bounds: [171.0, 692.0, 4047.0, 5754.0],
                    rates: [1.16, 0.95, 0.87, 0.82]
                ),
                ManualModalityEstimateLimitOffsetAdjuster(weight: 1.97),
                MinimumManualModalityEstimateAdjuster(minimum: 2.9),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 42455.1
        )
    }
}
