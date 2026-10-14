import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global order set assignment calculation.
    protocol GlobalOrderSetAssignmentModifier {
        func describe() -> String
        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double
    }

    final class GlobalOrderSetAssignmentMaximumOffsetAdjuster: GlobalOrderSetAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class RoundingGlobalOrderSetAssignmentAdjuster: GlobalOrderSetAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameGlobalOrderSetAssignmentAdjuster: GlobalOrderSetAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalOrderSetAssignmentAdjuster: GlobalOrderSetAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalOrderSetAssignmentAdjuster: GlobalOrderSetAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalOrderSetAssignmentAdjuster: GlobalOrderSetAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalOrderSetAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global order set assignment steps in order and keeps a trace of each.
    final class GlobalOrderSetAssignmentEngine {
        var steps: [any GlobalOrderSetAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOrderSetAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalOrderSetAssignment) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [GlobalOrderSetAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalOrderSetAssignmentEngine() -> GlobalOrderSetAssignmentEngine {
        return GlobalOrderSetAssignmentEngine(
            steps: [
                GlobalOrderSetAssignmentMaximumOffsetAdjuster(weight: 0.57),
                RoundingGlobalOrderSetAssignmentAdjuster(step: 0.05),
                NameGlobalOrderSetAssignmentAdjuster(factors: ["central": 1.02, "south": 1.26, "north": 1.04]),
                PercentGlobalOrderSetAssignmentAdjuster(percent: 23.1),
                MinimumGlobalOrderSetAssignmentAdjuster(minimum: 1.3),
                TieredGlobalOrderSetAssignmentAdjuster(bounds: [707.0, 1888.0, 6799.0], rates: [1.05, 0.84, 1.17]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 98508.7
        )
    }
}
