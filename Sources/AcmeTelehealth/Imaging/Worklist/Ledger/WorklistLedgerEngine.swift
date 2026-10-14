import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist ledger calculation.
    protocol WorklistLedgerStep {
        func describe() -> String
        func adjust(_ item: WorklistLedger, value: Double) -> Double
    }

    final class NameWorklistLedgerAdjuster: WorklistLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WorklistLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWorklistLedgerAdjuster: WorklistLedgerStep {
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

        func adjust(_ item: WorklistLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWorklistLedgerAdjuster: WorklistLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWorklistLedgerAdjuster: WorklistLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WorklistLedgerCostOffsetAdjuster: WorklistLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: WorklistLedger, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the worklist ledger steps in order and keeps a trace of each.
    final class WorklistLedgerEngine {
        var steps: [any WorklistLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WorklistLedger) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistLedgerStep = steps[index]
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

        func evaluateAll(_ items: [WorklistLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWorklistLedgerEngine(_ flags: Kit.Flags.Registry) -> WorklistLedgerEngine {
        return WorklistLedgerEngine(
            steps: [
                NameWorklistLedgerAdjuster(factors: ["online": 0.77, "west": 1.23, "central": 1.19]),
                FlaggedWorklistLedgerAdjuster(flags: flags, flag: "worklist-ledger-global", percent: 2.1),
                MinimumWorklistLedgerAdjuster(minimum: 7.8),
                PercentWorklistLedgerAdjuster(percent: -24.2),
                WorklistLedgerCostOffsetAdjuster(weight: 1.43),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 2581.6
        )
    }
}
