import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted care protocol profile calculation.
    protocol WeightedCareProtocolProfileModifier {
        func describe() -> String
        func adjust(_ item: WeightedCareProtocolProfile, value: Double) -> Double
    }

    final class WeightedCareProtocolProfileSequenceOffsetAdjuster: WeightedCareProtocolProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: WeightedCareProtocolProfile, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapWeightedCareProtocolProfileAdjuster: WeightedCareProtocolProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedCareProtocolProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedCareProtocolProfileAdjuster: WeightedCareProtocolProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedCareProtocolProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedCareProtocolProfileAdjuster: WeightedCareProtocolProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedCareProtocolProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedCareProtocolProfileAdjuster: WeightedCareProtocolProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedCareProtocolProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted care protocol profile steps in order and keeps a trace of each.
    final class WeightedCareProtocolProfileEngine {
        var steps: [any WeightedCareProtocolProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCareProtocolProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedCareProtocolProfile) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedCareProtocolProfileModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedCareProtocolProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedCareProtocolProfileEngine() -> WeightedCareProtocolProfileEngine {
        return WeightedCareProtocolProfileEngine(
            steps: [
                WeightedCareProtocolProfileSequenceOffsetAdjuster(weight: 1.94),
                CapWeightedCareProtocolProfileAdjuster(cap: 23811.0),
                RoundingWeightedCareProtocolProfileAdjuster(step: 0.5),
                PercentWeightedCareProtocolProfileAdjuster(percent: -13.8),
                TieredWeightedCareProtocolProfileAdjuster(bounds: [6180.0, 8974.0], rates: [1.1, 0.82]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 33978.6
        )
    }
}
