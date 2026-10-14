import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global inventory cycle calculation.
    protocol GlobalInventoryCycleAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double
    }

    final class RegionGlobalInventoryCycleAdjuster: GlobalInventoryCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalInventoryCycleAdjuster: GlobalInventoryCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalInventoryCycleAdjuster: GlobalInventoryCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalInventoryCycleQuantityOffsetAdjuster: GlobalInventoryCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentGlobalInventoryCycleAdjuster: GlobalInventoryCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalInventoryCycleAdjuster: GlobalInventoryCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalInventoryCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global inventory cycle steps in order and keeps a trace of each.
    final class GlobalInventoryCycleEngine {
        var steps: [any GlobalInventoryCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInventoryCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalInventoryCycle) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalInventoryCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalInventoryCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalInventoryCycleEngine() -> GlobalInventoryCycleEngine {
        return GlobalInventoryCycleEngine(
            steps: [
                RegionGlobalInventoryCycleAdjuster(factors: ["central": 1.01, "online": 1.13, "south": 1.12]),
                TieredGlobalInventoryCycleAdjuster(
                    bounds: [1634.0, 6238.0, 8262.0, 9921.0],
                    rates: [1.0, 1.01, 0.92, 1.11]
                ),
                RoundingGlobalInventoryCycleAdjuster(step: 5.0),
                GlobalInventoryCycleQuantityOffsetAdjuster(weight: 0.88),
                PercentGlobalInventoryCycleAdjuster(percent: 17.3),
                MinimumGlobalInventoryCycleAdjuster(minimum: 5.2),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 38518.8
        )
    }
}
