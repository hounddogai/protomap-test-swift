import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range ledger calculation.
    protocol ReferenceRangeLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeLedger, value: Double) -> Double
    }

    final class PercentReferenceRangeLedgerAdjuster: ReferenceRangeLedgerAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferenceRangeLedgerAdjuster: ReferenceRangeLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedReferenceRangeLedgerAdjuster: ReferenceRangeLedgerAdjuster {
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

        func adjust(_ item: ReferenceRangeLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReferenceRangeLedgerAdjuster: ReferenceRangeLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the reference range ledger steps in order and keeps a trace of each.
    final class ReferenceRangeLedgerEngine {
        var steps: [any ReferenceRangeLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeLedger) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeLedgerEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeLedgerEngine {
        return ReferenceRangeLedgerEngine(
            steps: [
                PercentReferenceRangeLedgerAdjuster(percent: 5.3),
                RoundingReferenceRangeLedgerAdjuster(step: 0.1),
                FlaggedReferenceRangeLedgerAdjuster(
                    flags: flags,
                    flag: "reference-range-ledger-scheduled",
                    percent: 6.9
                ),
                TieredReferenceRangeLedgerAdjuster(bounds: [999.0, 4599.0, 5568.0], rates: [0.8, 0.89, 0.81]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 67340.4
        )
    }
}
