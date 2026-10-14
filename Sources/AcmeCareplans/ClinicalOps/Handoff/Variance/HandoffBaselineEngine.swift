import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff baseline calculation.
    protocol HandoffBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffBaseline, value: Double) -> Double
    }

    final class HandoffBaselineRateOffsetAdjuster: HandoffBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: HandoffBaseline, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapHandoffBaselineAdjuster: HandoffBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingHandoffBaselineAdjuster: HandoffBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the handoff baseline steps in order and keeps a trace of each.
    final class HandoffBaselineEngine {
        var steps: [any HandoffBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [HandoffBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffBaselineEngine() -> HandoffBaselineEngine {
        return HandoffBaselineEngine(
            steps: [
                HandoffBaselineRateOffsetAdjuster(weight: 0.68),
                CapHandoffBaselineAdjuster(cap: 33097.0),
                RoundingHandoffBaselineAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 62747.6
        )
    }
}
