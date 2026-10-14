import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result ledger calculation.
    protocol ResultLedgerModifier {
        func describe() -> String
        func adjust(_ item: ResultLedger, value: Double) -> Double
    }

    final class FlaggedResultLedgerAdjuster: ResultLedgerModifier {
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

        func adjust(_ item: ResultLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentResultLedgerAdjuster: ResultLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ResultLedgerAmountOffsetAdjuster: ResultLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ResultLedger, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class ChannelResultLedgerAdjuster: ResultLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ResultLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the result ledger steps in order and keeps a trace of each.
    final class ResultLedgerEngine {
        var steps: [any ResultLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ResultLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultLedgerEngine(_ flags: Kit.Flags.Registry) -> ResultLedgerEngine {
        return ResultLedgerEngine(
            steps: [
                FlaggedResultLedgerAdjuster(flags: flags, flag: "result-ledger-weighted", percent: -9.9),
                PercentResultLedgerAdjuster(percent: 1.2),
                ResultLedgerAmountOffsetAdjuster(weight: 1.78),
                ChannelResultLedgerAdjuster(factors: ["retail": 0.83, "west": 0.74]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 5428.6
        )
    }
}
