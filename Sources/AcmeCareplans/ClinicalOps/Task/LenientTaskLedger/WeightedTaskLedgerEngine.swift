import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted task ledger calculation.
    protocol WeightedTaskLedgerStep {
        func describe() -> String
        func adjust(_ item: WeightedTaskLedger, value: Double) -> Double
    }

    final class RoundingWeightedTaskLedgerAdjuster: WeightedTaskLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedTaskLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedTaskLedgerCostOffsetAdjuster: WeightedTaskLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: WeightedTaskLedger, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class MinimumWeightedTaskLedgerAdjuster: WeightedTaskLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedTaskLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedTaskLedgerAdjuster: WeightedTaskLedgerStep {
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

        func adjust(_ item: WeightedTaskLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted task ledger steps in order and keeps a trace of each.
    final class WeightedTaskLedgerEngine {
        var steps: [any WeightedTaskLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTaskLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedTaskLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedTaskLedgerStep = steps[index]
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

        func evaluateAll(_ items: [WeightedTaskLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedTaskLedgerEngine(_ flags: Kit.Flags.Registry) -> WeightedTaskLedgerEngine {
        return WeightedTaskLedgerEngine(
            steps: [
                RoundingWeightedTaskLedgerAdjuster(step: 0.25),
                WeightedTaskLedgerCostOffsetAdjuster(weight: 0.62),
                MinimumWeightedTaskLedgerAdjuster(minimum: 19.5),
                FlaggedWeightedTaskLedgerAdjuster(flags: flags, flag: "weighted-task-ledger-regional", percent: -7.6),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 8041.8
        )
    }
}
