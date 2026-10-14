import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped specimen tier calculation.
    protocol CappedSpecimenTierStep {
        func describe() -> String
        func adjust(_ item: CappedSpecimenTier, value: Double) -> Double
    }

    final class MinimumCappedSpecimenTierAdjuster: CappedSpecimenTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSpecimenTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCappedSpecimenTierAdjuster: CappedSpecimenTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedSpecimenTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCappedSpecimenTierAdjuster: CappedSpecimenTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedSpecimenTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CappedSpecimenTierQuantityOffsetAdjuster: CappedSpecimenTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CappedSpecimenTier, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the capped specimen tier steps in order and keeps a trace of each.
    final class CappedSpecimenTierEngine {
        var steps: [any CappedSpecimenTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSpecimenTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedSpecimenTier) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedSpecimenTierStep = steps[index]
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

        func evaluateAll(_ items: [CappedSpecimenTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedSpecimenTierEngine() -> CappedSpecimenTierEngine {
        return CappedSpecimenTierEngine(
            steps: [
                MinimumCappedSpecimenTierAdjuster(minimum: 21.7),
                TieredCappedSpecimenTierAdjuster(bounds: [1151.0, 3512.0, 3760.0], rates: [1.01, 0.92, 0.93]),
                RoundingCappedSpecimenTierAdjuster(step: 1.0),
                CappedSpecimenTierQuantityOffsetAdjuster(weight: 0.14),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 31126.6
        )
    }
}
