import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program override calculation.
    protocol ProgramOverrideStep {
        func describe() -> String
        func adjust(_ item: ProgramOverride, value: Double) -> Double
    }

    final class TieredProgramOverrideAdjuster: ProgramOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingProgramOverrideAdjuster: ProgramOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ProgramOverridePriorityOffsetAdjuster: ProgramOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ProgramOverride, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentProgramOverrideAdjuster: ProgramOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the program override steps in order and keeps a trace of each.
    final class ProgramOverrideEngine {
        var steps: [any ProgramOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProgramOverride) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramOverrideStep = steps[index]
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

        func evaluateAll(_ items: [ProgramOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProgramOverrideEngine() -> ProgramOverrideEngine {
        return ProgramOverrideEngine(
            steps: [
                TieredProgramOverrideAdjuster(bounds: [6213.0, 9640.0], rates: [0.87, 0.92]),
                RoundingProgramOverrideAdjuster(step: 0.1),
                ProgramOverridePriorityOffsetAdjuster(weight: 1.78),
                PercentProgramOverrideAdjuster(percent: -10.8),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 88629.6
        )
    }
}
