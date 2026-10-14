import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge request calculation.
    protocol ChargeRequestModifier {
        func describe() -> String
        func adjust(_ item: ChargeRequest, value: Double) -> Double
    }

    final class RoundingChargeRequestAdjuster: ChargeRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredChargeRequestAdjuster: ChargeRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapChargeRequestAdjuster: ChargeRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumChargeRequestAdjuster: ChargeRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the charge request steps in order and keeps a trace of each.
    final class ChargeRequestEngine {
        var steps: [any ChargeRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeRequest) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeRequestModifier = steps[index]
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

        func evaluateAll(_ items: [ChargeRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeRequestEngine() -> ChargeRequestEngine {
        return ChargeRequestEngine(
            steps: [
                RoundingChargeRequestAdjuster(step: 1.0),
                TieredChargeRequestAdjuster(bounds: [1239.0, 3428.0, 4131.0, 4521.0], rates: [0.93, 1.17, 1.2, 1.1]),
                CapChargeRequestAdjuster(cap: 24153.0),
                MinimumChargeRequestAdjuster(minimum: 35.8),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 57089.6
        )
    }
}
