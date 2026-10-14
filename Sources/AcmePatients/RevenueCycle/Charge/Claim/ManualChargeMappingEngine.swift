import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual charge mapping calculation.
    protocol ManualChargeMappingStep {
        func describe() -> String
        func adjust(_ item: ManualChargeMapping, value: Double) -> Double
    }

    final class ManualChargeMappingSequenceOffsetAdjuster: ManualChargeMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ManualChargeMapping, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingManualChargeMappingAdjuster: ManualChargeMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualChargeMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualChargeMappingAdjuster: ManualChargeMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualChargeMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual charge mapping steps in order and keeps a trace of each.
    final class ManualChargeMappingEngine {
        var steps: [any ManualChargeMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualChargeMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualChargeMapping) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualChargeMappingStep = steps[index]
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

        func evaluateAll(_ items: [ManualChargeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualChargeMappingEngine() -> ManualChargeMappingEngine {
        return ManualChargeMappingEngine(
            steps: [
                ManualChargeMappingSequenceOffsetAdjuster(weight: 0.1),
                RoundingManualChargeMappingAdjuster(step: 5.0),
                TieredManualChargeMappingAdjuster(bounds: [1792.0, 6364.0], rates: [1.13, 0.8]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 24647.0
        )
    }
}
