import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary discharge plan ledger calculation.
    protocol PrimaryDischargePlanLedgerStep {
        func describe() -> String
        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double
    }

    final class TieredPrimaryDischargePlanLedgerAdjuster: PrimaryDischargePlanLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PrimaryDischargePlanLedgerAcuityOffsetAdjuster: PrimaryDischargePlanLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class PercentPrimaryDischargePlanLedgerAdjuster: PrimaryDischargePlanLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryDischargePlanLedgerAdjuster: PrimaryDischargePlanLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardPrimaryDischargePlanLedgerAdjuster: PrimaryDischargePlanLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryDischargePlanLedgerAdjuster: PrimaryDischargePlanLedgerStep {
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

        func adjust(_ item: PrimaryDischargePlanLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary discharge plan ledger steps in order and keeps a trace of each.
    final class PrimaryDischargePlanLedgerEngine {
        var steps: [any PrimaryDischargePlanLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDischargePlanLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryDischargePlanLedger) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryDischargePlanLedgerStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryDischargePlanLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryDischargePlanLedgerEngine(_ flags: Kit.Flags.Registry) -> PrimaryDischargePlanLedgerEngine {
        return PrimaryDischargePlanLedgerEngine(
            steps: [
                TieredPrimaryDischargePlanLedgerAdjuster(bounds: [1331.0, 8255.0, 8414.0], rates: [0.92, 1.07, 0.93]),
                PrimaryDischargePlanLedgerAcuityOffsetAdjuster(weight: 1.14),
                PercentPrimaryDischargePlanLedgerAdjuster(percent: -10.5),
                RoundingPrimaryDischargePlanLedgerAdjuster(step: 1.0),
                WardPrimaryDischargePlanLedgerAdjuster(factors: ["north": 0.97, "retail": 0.82]),
                FlaggedPrimaryDischargePlanLedgerAdjuster(
                    flags: flags,
                    flag: "primary-discharge-plan-ledger-pending",
                    percent: -4.9
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 82079.7
        )
    }
}
