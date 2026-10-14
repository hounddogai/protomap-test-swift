import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped disclosure ledger calculation.
    protocol CappedDisclosureLedgerStep {
        func describe() -> String
        func adjust(_ item: CappedDisclosureLedger, value: Double) -> Double
    }

    final class CapCappedDisclosureLedgerAdjuster: CappedDisclosureLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedDisclosureLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedDisclosureLedgerAdjuster: CappedDisclosureLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedDisclosureLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedDisclosureLedgerUpdatedAtOffsetAdjuster: CappedDisclosureLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: CappedDisclosureLedger, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TieredCappedDisclosureLedgerAdjuster: CappedDisclosureLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedDisclosureLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped disclosure ledger steps in order and keeps a trace of each.
    final class CappedDisclosureLedgerEngine {
        var steps: [any CappedDisclosureLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedDisclosureLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedDisclosureLedger) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CappedDisclosureLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedDisclosureLedgerEngine() -> CappedDisclosureLedgerEngine {
        return CappedDisclosureLedgerEngine(
            steps: [
                CapCappedDisclosureLedgerAdjuster(cap: 13728.0),
                MinimumCappedDisclosureLedgerAdjuster(minimum: 19.3),
                CappedDisclosureLedgerUpdatedAtOffsetAdjuster(weight: 0.33),
                TieredCappedDisclosureLedgerAdjuster(bounds: [5101.0, 6616.0], rates: [1.04, 1.09]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 10982.5
        )
    }
}
