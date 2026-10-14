import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness mapping calculation.
    protocol WitnessMappingFactor {
        func describe() -> String
        func adjust(_ item: WitnessMapping, value: Double) -> Double
    }

    final class RoundingWitnessMappingAdjuster: WitnessMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WitnessMappingDiscountOffsetAdjuster: WitnessMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: WitnessMapping, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentWitnessMappingAdjuster: WitnessMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness mapping steps in order and keeps a trace of each.
    final class WitnessMappingEngine {
        var steps: [any WitnessMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WitnessMapping) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WitnessMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWitnessMappingEngine() -> WitnessMappingEngine {
        return WitnessMappingEngine(
            steps: [
                RoundingWitnessMappingAdjuster(step: 0.05),
                WitnessMappingDiscountOffsetAdjuster(weight: 1.06),
                PercentWitnessMappingAdjuster(percent: -9.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 37958.9
        )
    }
}
