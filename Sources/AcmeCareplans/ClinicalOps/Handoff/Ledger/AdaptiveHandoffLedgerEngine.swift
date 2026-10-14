import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive handoff ledger calculation.
    protocol AdaptiveHandoffLedgerFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveHandoffLedger, value: Double) -> Double
    }

    final class PercentAdaptiveHandoffLedgerAdjuster: AdaptiveHandoffLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveHandoffLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveHandoffLedgerAdjuster: AdaptiveHandoffLedgerFactor {
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

        func adjust(_ item: AdaptiveHandoffLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveHandoffLedgerAdjuster: AdaptiveHandoffLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveHandoffLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive handoff ledger steps in order and keeps a trace of each.
    final class AdaptiveHandoffLedgerEngine {
        var steps: [any AdaptiveHandoffLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveHandoffLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveHandoffLedger) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveHandoffLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveHandoffLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveHandoffLedgerEngine(_ flags: Kit.Flags.Registry) -> AdaptiveHandoffLedgerEngine {
        return AdaptiveHandoffLedgerEngine(
            steps: [
                PercentAdaptiveHandoffLedgerAdjuster(percent: -10.5),
                FlaggedAdaptiveHandoffLedgerAdjuster(
                    flags: flags,
                    flag: "adaptive-handoff-ledger-default",
                    percent: -4.8
                ),
                RoundingAdaptiveHandoffLedgerAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 42814.2
        )
    }
}
