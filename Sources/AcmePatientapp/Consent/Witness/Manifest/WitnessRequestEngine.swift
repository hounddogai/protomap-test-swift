import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness request calculation.
    protocol WitnessRequestStep {
        func describe() -> String
        func adjust(_ item: WitnessRequest, value: Double) -> Double
    }

    final class RoundingWitnessRequestAdjuster: WitnessRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WitnessRequestVersionOffsetAdjuster: WitnessRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: WitnessRequest, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class MinimumWitnessRequestAdjuster: WitnessRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the witness request steps in order and keeps a trace of each.
    final class WitnessRequestEngine {
        var steps: [any WitnessRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessRequest) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [WitnessRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessRequestEngine() -> WitnessRequestEngine {
        return WitnessRequestEngine(
            steps: [
                RoundingWitnessRequestAdjuster(step: 0.1),
                WitnessRequestVersionOffsetAdjuster(weight: 0.89),
                MinimumWitnessRequestAdjuster(minimum: 37.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 78566.6
        )
    }
}
