import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff ledger calculation.
    protocol HandoffLedgerStep {
        func describe() -> String
        func adjust(_ item: HandoffLedger, value: Double) -> Double
    }

    final class FlaggedHandoffLedgerAdjuster: HandoffLedgerStep {
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

        func adjust(_ item: HandoffLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapHandoffLedgerAdjuster: HandoffLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingHandoffLedgerAdjuster: HandoffLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumHandoffLedgerAdjuster: HandoffLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleHandoffLedgerAdjuster: HandoffLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: HandoffLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentHandoffLedgerAdjuster: HandoffLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff ledger steps in order and keeps a trace of each.
    final class HandoffLedgerEngine {
        var steps: [any HandoffLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: HandoffLedger) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffLedgerStep = steps[index]
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

        func evaluateAll(_ items: [HandoffLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultHandoffLedgerEngine(_ flags: Kit.Flags.Registry) -> HandoffLedgerEngine {
        return HandoffLedgerEngine(
            steps: [
                FlaggedHandoffLedgerAdjuster(flags: flags, flag: "handoff-ledger-seasonal", percent: -0.1),
                CapHandoffLedgerAdjuster(cap: 2245.0),
                RoundingHandoffLedgerAdjuster(step: 0.05),
                MinimumHandoffLedgerAdjuster(minimum: 23.2),
                TitleHandoffLedgerAdjuster(factors: ["central": 1.25, "east": 0.99]),
                PercentHandoffLedgerAdjuster(percent: 4.5),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 16443.0
        )
    }
}
