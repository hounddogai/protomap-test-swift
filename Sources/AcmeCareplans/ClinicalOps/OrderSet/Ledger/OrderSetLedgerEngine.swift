import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set ledger calculation.
    protocol OrderSetLedgerFactor {
        func describe() -> String
        func adjust(_ item: OrderSetLedger, value: Double) -> Double
    }

    final class MinimumOrderSetLedgerAdjuster: OrderSetLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class OrderSetLedgerDosageMgOffsetAdjuster: OrderSetLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: OrderSetLedger, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class FlaggedOrderSetLedgerAdjuster: OrderSetLedgerFactor {
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

        func adjust(_ item: OrderSetLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOrderSetLedgerAdjuster: OrderSetLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityOrderSetLedgerAdjuster: OrderSetLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: OrderSetLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapOrderSetLedgerAdjuster: OrderSetLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the order set ledger steps in order and keeps a trace of each.
    final class OrderSetLedgerEngine {
        var steps: [any OrderSetLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetLedger) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [OrderSetLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetLedgerEngine(_ flags: Kit.Flags.Registry) -> OrderSetLedgerEngine {
        return OrderSetLedgerEngine(
            steps: [
                MinimumOrderSetLedgerAdjuster(minimum: 33.8),
                OrderSetLedgerDosageMgOffsetAdjuster(weight: 0.39),
                FlaggedOrderSetLedgerAdjuster(flags: flags, flag: "order-set-ledger-scheduled", percent: 2.2),
                TieredOrderSetLedgerAdjuster(
                    bounds: [4865.0, 5424.0, 7556.0, 8229.0],
                    rates: [1.16, 0.88, 0.99, 0.95]
                ),
                FacilityOrderSetLedgerAdjuster(factors: ["online": 1.3]),
                CapOrderSetLedgerAdjuster(cap: 45174.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 83055.5
        )
    }
}
