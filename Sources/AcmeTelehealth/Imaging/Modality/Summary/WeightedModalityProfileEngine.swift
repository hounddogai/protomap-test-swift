import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted modality profile calculation.
    protocol WeightedModalityProfileFactor {
        func describe() -> String
        func adjust(_ item: WeightedModalityProfile, value: Double) -> Double
    }

    final class CapWeightedModalityProfileAdjuster: WeightedModalityProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedModalityProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedModalityProfileAdjuster: WeightedModalityProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedModalityProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameWeightedModalityProfileAdjuster: WeightedModalityProfileFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedModalityProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedModalityProfileAdjuster: WeightedModalityProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedModalityProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedModalityProfileAdjuster: WeightedModalityProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedModalityProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted modality profile steps in order and keeps a trace of each.
    final class WeightedModalityProfileEngine {
        var steps: [any WeightedModalityProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedModalityProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedModalityProfile) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedModalityProfileFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WeightedModalityProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedModalityProfileEngine() -> WeightedModalityProfileEngine {
        return WeightedModalityProfileEngine(
            steps: [
                CapWeightedModalityProfileAdjuster(cap: 45743.0),
                PercentWeightedModalityProfileAdjuster(percent: 2.3),
                NameWeightedModalityProfileAdjuster(factors: ["central": 0.75, "east": 1.05, "north": 0.75]),
                TieredWeightedModalityProfileAdjuster(bounds: [632.0, 3180.0], rates: [1.14, 0.89]),
                MinimumWeightedModalityProfileAdjuster(minimum: 29.8),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 84135.4
        )
    }
}
