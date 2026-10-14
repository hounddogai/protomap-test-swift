import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge override calculation.
    protocol ChargeOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: ChargeOverride, value: Double) -> Double
    }

    final class RoundingChargeOverrideAdjuster: ChargeOverrideAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentChargeOverrideAdjuster: ChargeOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChargeOverrideRateOffsetAdjuster: ChargeOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ChargeOverride, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the charge override steps in order and keeps a trace of each.
    final class ChargeOverrideEngine {
        var steps: [any ChargeOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ChargeOverride) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [ChargeOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultChargeOverrideEngine() -> ChargeOverrideEngine {
        return ChargeOverrideEngine(
            steps: [
                RoundingChargeOverrideAdjuster(step: 0.1),
                PercentChargeOverrideAdjuster(percent: 13.3),
                ChargeOverrideRateOffsetAdjuster(weight: 1.63),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 29191.9
        )
    }
}
