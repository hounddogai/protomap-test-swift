import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality assignment calculation.
    protocol CappedModalityAssignmentStep {
        func describe() -> String
        func adjust(_ item: CappedModalityAssignment, value: Double) -> Double
    }

    final class FlaggedCappedModalityAssignmentAdjuster: CappedModalityAssignmentStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: CappedModalityAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedModalityAssignmentAdjuster: CappedModalityAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedModalityAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCappedModalityAssignmentAdjuster: CappedModalityAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedModalityAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedModalityAssignmentMaximumOffsetAdjuster: CappedModalityAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CappedModalityAssignment, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class PercentCappedModalityAssignmentAdjuster: CappedModalityAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedModalityAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped modality assignment steps in order and keeps a trace of each.
    final class CappedModalityAssignmentEngine {
        var steps: [any CappedModalityAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedModalityAssignment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedModalityAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [CappedModalityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedModalityAssignmentEngine(_ flags: Kit.Flags.Registry) -> CappedModalityAssignmentEngine {
        return CappedModalityAssignmentEngine(
            steps: [
                FlaggedCappedModalityAssignmentAdjuster(
                    flags: flags,
                    flag: "capped-modality-assignment-pending",
                    percent: -8.3
                ),
                TieredCappedModalityAssignmentAdjuster(bounds: [3482.0, 5970.0, 6494.0], rates: [1.07, 1.09, 0.96]),
                CapCappedModalityAssignmentAdjuster(cap: 32584.0),
                CappedModalityAssignmentMaximumOffsetAdjuster(weight: 0.79),
                PercentCappedModalityAssignmentAdjuster(percent: 18.3),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 97585.1
        )
    }
}
