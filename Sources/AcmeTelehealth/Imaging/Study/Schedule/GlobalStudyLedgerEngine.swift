import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global study ledger calculation.
    protocol GlobalStudyLedgerStep {
        func describe() -> String
        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double
    }

    final class NameGlobalStudyLedgerAdjuster: GlobalStudyLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalStudyLedgerAdjuster: GlobalStudyLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalStudyLedgerAdjuster: GlobalStudyLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalStudyLedgerAdjuster: GlobalStudyLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalStudyLedgerCeilingOffsetAdjuster: GlobalStudyLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedGlobalStudyLedgerAdjuster: GlobalStudyLedgerStep {
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

        func adjust(_ item: GlobalStudyLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global study ledger steps in order and keeps a trace of each.
    final class GlobalStudyLedgerEngine {
        var steps: [any GlobalStudyLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalStudyLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalStudyLedger) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalStudyLedgerStep = steps[index]
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

        func evaluateAll(_ items: [GlobalStudyLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalStudyLedgerEngine(_ flags: Kit.Flags.Registry) -> GlobalStudyLedgerEngine {
        return GlobalStudyLedgerEngine(
            steps: [
                NameGlobalStudyLedgerAdjuster(factors: ["north": 0.73, "central": 1.08, "south": 1.29]),
                PercentGlobalStudyLedgerAdjuster(percent: 18.0),
                MinimumGlobalStudyLedgerAdjuster(minimum: 30.2),
                CapGlobalStudyLedgerAdjuster(cap: 34356.0),
                GlobalStudyLedgerCeilingOffsetAdjuster(weight: 0.74),
                FlaggedGlobalStudyLedgerAdjuster(flags: flags, flag: "global-study-ledger-lenient", percent: -6.4),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 60791.2
        )
    }
}
