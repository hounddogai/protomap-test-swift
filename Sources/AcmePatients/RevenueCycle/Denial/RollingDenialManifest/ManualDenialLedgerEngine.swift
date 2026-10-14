import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual denial ledger calculation.
    protocol ManualDenialLedgerStep {
        func describe() -> String
        func adjust(_ item: ManualDenialLedger, value: Double) -> Double
    }

    final class ManualDenialLedgerCeilingOffsetAdjuster: ManualDenialLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ManualDenialLedger, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class TieredManualDenialLedgerAdjuster: ManualDenialLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDenialLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityManualDenialLedgerAdjuster: ManualDenialLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ManualDenialLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualDenialLedgerAdjuster: ManualDenialLedgerStep {
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

        func adjust(_ item: ManualDenialLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualDenialLedgerAdjuster: ManualDenialLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDenialLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualDenialLedgerAdjuster: ManualDenialLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDenialLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual denial ledger steps in order and keeps a trace of each.
    final class ManualDenialLedgerEngine {
        var steps: [any ManualDenialLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDenialLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualDenialLedger) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDenialLedgerStep = steps[index]
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

        func evaluateAll(_ items: [ManualDenialLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualDenialLedgerEngine(_ flags: Kit.Flags.Registry) -> ManualDenialLedgerEngine {
        return ManualDenialLedgerEngine(
            steps: [
                ManualDenialLedgerCeilingOffsetAdjuster(weight: 0.09),
                TieredManualDenialLedgerAdjuster(bounds: [4857.0, 8078.0], rates: [1.12, 1.19]),
                FacilityManualDenialLedgerAdjuster(factors: ["east": 1.18]),
                FlaggedManualDenialLedgerAdjuster(flags: flags, flag: "manual-denial-ledger-seasonal", percent: 3.6),
                RoundingManualDenialLedgerAdjuster(step: 0.5),
                CapManualDenialLedgerAdjuster(cap: 49706.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 31673.8
        )
    }
}
