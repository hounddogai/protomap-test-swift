import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual float pool summary calculation.
    protocol ManualFloatPoolSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: ManualFloatPoolSummary, value: Double) -> Double
    }

    final class ManualFloatPoolSummaryMaximumOffsetAdjuster: ManualFloatPoolSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ManualFloatPoolSummary, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumManualFloatPoolSummaryAdjuster: ManualFloatPoolSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualFloatPoolSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualFloatPoolSummaryAdjuster: ManualFloatPoolSummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualFloatPoolSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual float pool summary steps in order and keeps a trace of each.
    final class ManualFloatPoolSummaryEngine {
        var steps: [any ManualFloatPoolSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFloatPoolSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualFloatPoolSummary) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualFloatPoolSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualFloatPoolSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualFloatPoolSummaryEngine() -> ManualFloatPoolSummaryEngine {
        return ManualFloatPoolSummaryEngine(
            steps: [
                ManualFloatPoolSummaryMaximumOffsetAdjuster(weight: 1.35),
                MinimumManualFloatPoolSummaryAdjuster(minimum: 26.1),
                RoundingManualFloatPoolSummaryAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 35743.4
        )
    }
}
