import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding slot calculation.
    protocol RoundingSlotAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingSlot, value: Double) -> Double
    }

    final class RoundingRoundingSlotAdjuster: RoundingSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameRoundingSlotAdjuster: RoundingSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RoundingSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRoundingSlotAdjuster: RoundingSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRoundingSlotAdjuster: RoundingSlotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRoundingSlotAdjuster: RoundingSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rounding slot steps in order and keeps a trace of each.
    final class RoundingSlotEngine {
        var steps: [any RoundingSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingSlotAdjuster = steps[index]
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

        func evaluateAll(_ items: [RoundingSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingSlotEngine() -> RoundingSlotEngine {
        return RoundingSlotEngine(
            steps: [
                RoundingRoundingSlotAdjuster(step: 0.5),
                NameRoundingSlotAdjuster(factors: ["west": 0.97, "central": 1.21, "east": 0.76]),
                TieredRoundingSlotAdjuster(bounds: [3487.0, 8679.0, 9398.0, 9439.0], rates: [1.19, 0.94, 0.91, 1.16]),
                PercentRoundingSlotAdjuster(percent: -20.2),
                MinimumRoundingSlotAdjuster(minimum: 23.7),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 2659.6
        )
    }
}
