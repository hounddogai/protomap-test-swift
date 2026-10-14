import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime policy calculation.
    protocol OvertimePolicyFactor {
        func describe() -> String
        func adjust(_ item: OvertimePolicy, value: Double) -> Double
    }

    final class MinimumOvertimePolicyAdjuster: OvertimePolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimePolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredOvertimePolicyAdjuster: OvertimePolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OvertimePolicyRateOffsetAdjuster: OvertimePolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: OvertimePolicy, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class RoundingOvertimePolicyAdjuster: OvertimePolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the overtime policy steps in order and keeps a trace of each.
    final class OvertimePolicyEngine {
        var steps: [any OvertimePolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimePolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimePolicy) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimePolicyFactor = steps[index]
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

        func evaluateAll(_ items: [OvertimePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimePolicyEngine() -> OvertimePolicyEngine {
        return OvertimePolicyEngine(
            steps: [
                MinimumOvertimePolicyAdjuster(minimum: 36.4),
                TieredOvertimePolicyAdjuster(
                    bounds: [1892.0, 7479.0, 8974.0, 9055.0],
                    rates: [1.09, 1.06, 1.09, 0.97]
                ),
                OvertimePolicyRateOffsetAdjuster(weight: 0.28),
                RoundingOvertimePolicyAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 16100.9
        )
    }
}
