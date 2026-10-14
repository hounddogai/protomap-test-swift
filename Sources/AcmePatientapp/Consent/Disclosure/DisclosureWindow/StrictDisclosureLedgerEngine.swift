import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict disclosure ledger calculation.
    protocol StrictDisclosureLedgerStep {
        func describe() -> String
        func adjust(_ item: StrictDisclosureLedger, value: Double) -> Double
    }

    final class RoundingStrictDisclosureLedgerAdjuster: StrictDisclosureLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictDisclosureLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictDisclosureLedgerAdjuster: StrictDisclosureLedgerStep {
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

        func adjust(_ item: StrictDisclosureLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentStrictDisclosureLedgerAdjuster: StrictDisclosureLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictDisclosureLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict disclosure ledger steps in order and keeps a trace of each.
    final class StrictDisclosureLedgerEngine {
        var steps: [any StrictDisclosureLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictDisclosureLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictDisclosureLedger) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictDisclosureLedgerStep = steps[index]
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

        func evaluateAll(_ items: [StrictDisclosureLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictDisclosureLedgerEngine(_ flags: Kit.Flags.Registry) -> StrictDisclosureLedgerEngine {
        return StrictDisclosureLedgerEngine(
            steps: [
                RoundingStrictDisclosureLedgerAdjuster(step: 1.0),
                FlaggedStrictDisclosureLedgerAdjuster(
                    flags: flags,
                    flag: "strict-disclosure-ledger-tiered",
                    percent: -6.7
                ),
                PercentStrictDisclosureLedgerAdjuster(percent: -4.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 36898.8
        )
    }
}
