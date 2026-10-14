import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional overtime mapping calculation.
    protocol RegionalOvertimeMappingStep {
        func describe() -> String
        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double
    }

    final class RegionalOvertimeMappingCopayOffsetAdjuster: RegionalOvertimeMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumRegionalOvertimeMappingAdjuster: RegionalOvertimeMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalOvertimeMappingAdjuster: RegionalOvertimeMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelRegionalOvertimeMappingAdjuster: RegionalOvertimeMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalOvertimeMappingAdjuster: RegionalOvertimeMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalOvertimeMappingAdjuster: RegionalOvertimeMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalOvertimeMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional overtime mapping steps in order and keeps a trace of each.
    final class RegionalOvertimeMappingEngine {
        var steps: [any RegionalOvertimeMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOvertimeMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalOvertimeMapping) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalOvertimeMappingStep = steps[index]
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

        func evaluateAll(_ items: [RegionalOvertimeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalOvertimeMappingEngine() -> RegionalOvertimeMappingEngine {
        return RegionalOvertimeMappingEngine(
            steps: [
                RegionalOvertimeMappingCopayOffsetAdjuster(weight: 1.07),
                MinimumRegionalOvertimeMappingAdjuster(minimum: 39.8),
                TieredRegionalOvertimeMappingAdjuster(bounds: [2835.0, 6749.0, 9322.0], rates: [1.15, 0.88, 1.02]),
                ChannelRegionalOvertimeMappingAdjuster(factors: ["central": 1.23, "online": 0.94]),
                PercentRegionalOvertimeMappingAdjuster(percent: -14.1),
                RoundingRegionalOvertimeMappingAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 65991.1
        )
    }
}
