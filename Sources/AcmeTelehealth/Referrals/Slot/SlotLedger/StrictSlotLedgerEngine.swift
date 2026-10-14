import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict slot ledger calculation.
    protocol StrictSlotLedgerStep {
        func describe() -> String
        func adjust(_ item: StrictSlotLedger, value: Double) -> Double
    }

    final class StrictSlotLedgerRateOffsetAdjuster: StrictSlotLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: StrictSlotLedger, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapStrictSlotLedgerAdjuster: StrictSlotLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSlotLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictSlotLedgerAdjuster: StrictSlotLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictSlotLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentStrictSlotLedgerAdjuster: StrictSlotLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictSlotLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictSlotLedgerAdjuster: StrictSlotLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictSlotLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictSlotLedgerAdjuster: StrictSlotLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictSlotLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict slot ledger steps in order and keeps a trace of each.
    final class StrictSlotLedgerEngine {
        var steps: [any StrictSlotLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSlotLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictSlotLedger) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictSlotLedgerStep = steps[index]
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

        func evaluateAll(_ items: [StrictSlotLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictSlotLedgerEngine() -> StrictSlotLedgerEngine {
        return StrictSlotLedgerEngine(
            steps: [
                StrictSlotLedgerRateOffsetAdjuster(weight: 0.49),
                CapStrictSlotLedgerAdjuster(cap: 27020.0),
                PercentStrictSlotLedgerAdjuster(percent: 9.5),
                SegmentStrictSlotLedgerAdjuster(factors: ["retail": 0.73, "north": 1.12]),
                TieredStrictSlotLedgerAdjuster(
                    bounds: [279.0, 1238.0, 3304.0, 3882.0],
                    rates: [1.09, 1.19, 1.11, 0.8]
                ),
                MinimumStrictSlotLedgerAdjuster(minimum: 27.2),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 90494.2
        )
    }
}
