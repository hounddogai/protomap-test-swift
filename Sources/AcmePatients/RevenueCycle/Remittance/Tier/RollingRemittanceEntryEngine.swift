import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling remittance entry calculation.
    protocol RollingRemittanceEntryAdjuster {
        func describe() -> String
        func adjust(_ item: RollingRemittanceEntry, value: Double) -> Double
    }

    final class PercentRollingRemittanceEntryAdjuster: RollingRemittanceEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingRemittanceEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingRemittanceEntryAdjuster: RollingRemittanceEntryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingRemittanceEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingRemittanceEntryFloorValueOffsetAdjuster: RollingRemittanceEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: RollingRemittanceEntry, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CategoryRollingRemittanceEntryAdjuster: RollingRemittanceEntryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RollingRemittanceEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingRemittanceEntryAdjuster: RollingRemittanceEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRemittanceEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling remittance entry steps in order and keeps a trace of each.
    final class RollingRemittanceEntryEngine {
        var steps: [any RollingRemittanceEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRemittanceEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingRemittanceEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingRemittanceEntryAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingRemittanceEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingRemittanceEntryEngine() -> RollingRemittanceEntryEngine {
        return RollingRemittanceEntryEngine(
            steps: [
                PercentRollingRemittanceEntryAdjuster(percent: 5.9),
                RoundingRollingRemittanceEntryAdjuster(step: 1.0),
                RollingRemittanceEntryFloorValueOffsetAdjuster(weight: 1.98),
                CategoryRollingRemittanceEntryAdjuster(factors: ["central": 0.98, "online": 0.73, "south": 1.24]),
                TieredRollingRemittanceEntryAdjuster(bounds: [5886.0, 7194.0], rates: [0.89, 0.82]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 56880.9
        )
    }
}
