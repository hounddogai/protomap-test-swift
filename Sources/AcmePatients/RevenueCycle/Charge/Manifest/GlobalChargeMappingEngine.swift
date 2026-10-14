import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global charge mapping calculation.
    protocol GlobalChargeMappingFactor {
        func describe() -> String
        func adjust(_ item: GlobalChargeMapping, value: Double) -> Double
    }

    final class GlobalChargeMappingRetriesOffsetAdjuster: GlobalChargeMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: GlobalChargeMapping, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumGlobalChargeMappingAdjuster: GlobalChargeMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalChargeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalChargeMappingAdjuster: GlobalChargeMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalChargeMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalChargeMappingAdjuster: GlobalChargeMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalChargeMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global charge mapping steps in order and keeps a trace of each.
    final class GlobalChargeMappingEngine {
        var steps: [any GlobalChargeMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalChargeMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalChargeMapping) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalChargeMappingFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalChargeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalChargeMappingEngine() -> GlobalChargeMappingEngine {
        return GlobalChargeMappingEngine(
            steps: [
                GlobalChargeMappingRetriesOffsetAdjuster(weight: 0.95),
                MinimumGlobalChargeMappingAdjuster(minimum: 21.3),
                CapGlobalChargeMappingAdjuster(cap: 18880.0),
                RoundingGlobalChargeMappingAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 2464.3
        )
    }
}
