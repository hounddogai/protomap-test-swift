import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the primary charge target calculation.
    protocol PrimaryChargeTargetStep {
        func describe() -> String
        func adjust(_ item: PrimaryChargeTarget, value: Double) -> Double
    }

    final class ChannelPrimaryChargeTargetAdjuster: PrimaryChargeTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryChargeTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimaryChargeTargetMaximumOffsetAdjuster: PrimaryChargeTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: PrimaryChargeTarget, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumPrimaryChargeTargetAdjuster: PrimaryChargeTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryChargeTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary charge target steps in order and keeps a trace of each.
    final class PrimaryChargeTargetEngine {
        var steps: [any PrimaryChargeTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryChargeTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryChargeTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryChargeTargetStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryChargeTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryChargeTargetEngine() -> PrimaryChargeTargetEngine {
        return PrimaryChargeTargetEngine(
            steps: [
                ChannelPrimaryChargeTargetAdjuster(factors: ["south": 1.3, "online": 1.19, "retail": 1.03]),
                PrimaryChargeTargetMaximumOffsetAdjuster(weight: 0.3),
                MinimumPrimaryChargeTargetAdjuster(minimum: 21.3),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 47739.3
        )
    }
}
