import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge ledger calculation.
    protocol ChargeLedgerFactor {
        func describe() -> String
        func adjust(_ item: ChargeLedger, value: Double) -> Double
    }

    final class MinimumChargeLedgerAdjuster: ChargeLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapChargeLedgerAdjuster: ChargeLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredChargeLedgerAdjuster: ChargeLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChargeLedgerEndsAtOffsetAdjuster: ChargeLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ChargeLedger, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the charge ledger steps in order and keeps a trace of each.
    final class ChargeLedgerEngine {
        var steps: [any ChargeLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeLedger) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ChargeLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeLedgerEngine() -> ChargeLedgerEngine {
        return ChargeLedgerEngine(
            steps: [
                MinimumChargeLedgerAdjuster(minimum: 37.1),
                CapChargeLedgerAdjuster(cap: 49033.0),
                TieredChargeLedgerAdjuster(bounds: [1049.0, 2634.0, 9456.0, 9548.0], rates: [0.94, 1.17, 0.87, 1.07]),
                ChargeLedgerEndsAtOffsetAdjuster(weight: 1.67),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 83843.7
        )
    }
}
