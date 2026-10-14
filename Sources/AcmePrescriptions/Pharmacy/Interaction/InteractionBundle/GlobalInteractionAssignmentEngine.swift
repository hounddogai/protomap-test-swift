import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global interaction assignment calculation.
    protocol GlobalInteractionAssignmentStep {
        func describe() -> String
        func adjust(_ item: GlobalInteractionAssignment, value: Double) -> Double
    }

    final class GlobalInteractionAssignmentRevisionOffsetAdjuster: GlobalInteractionAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: GlobalInteractionAssignment, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class RoundingGlobalInteractionAssignmentAdjuster: GlobalInteractionAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalInteractionAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGlobalInteractionAssignmentAdjuster: GlobalInteractionAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInteractionAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global interaction assignment steps in order and keeps a trace of each.
    final class GlobalInteractionAssignmentEngine {
        var steps: [any GlobalInteractionAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInteractionAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalInteractionAssignment) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalInteractionAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [GlobalInteractionAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalInteractionAssignmentEngine() -> GlobalInteractionAssignmentEngine {
        return GlobalInteractionAssignmentEngine(
            steps: [
                GlobalInteractionAssignmentRevisionOffsetAdjuster(weight: 1.56),
                RoundingGlobalInteractionAssignmentAdjuster(step: 0.1),
                TieredGlobalInteractionAssignmentAdjuster(
                    bounds: [1964.0, 4487.0, 5343.0, 5511.0],
                    rates: [0.93, 0.93, 0.98, 1.16]
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 79413.9
        )
    }
}
