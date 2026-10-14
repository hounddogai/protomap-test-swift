import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending handoff ledger calculation.
    protocol PendingHandoffLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double
    }

    final class PendingHandoffLedgerQuantityOffsetAdjuster: PendingHandoffLedgerAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapPendingHandoffLedgerAdjuster: PendingHandoffLedgerAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingHandoffLedgerAdjuster: PendingHandoffLedgerAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingHandoffLedgerAdjuster: PendingHandoffLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPendingHandoffLedgerAdjuster: PendingHandoffLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryPendingHandoffLedgerAdjuster: PendingHandoffLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PendingHandoffLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending handoff ledger steps in order and keeps a trace of each.
    final class PendingHandoffLedgerEngine {
        var steps: [any PendingHandoffLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingHandoffLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingHandoffLedger) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingHandoffLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingHandoffLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingHandoffLedgerEngine() -> PendingHandoffLedgerEngine {
        return PendingHandoffLedgerEngine(
            steps: [
                PendingHandoffLedgerQuantityOffsetAdjuster(weight: 1.25),
                CapPendingHandoffLedgerAdjuster(cap: 24362.0),
                PercentPendingHandoffLedgerAdjuster(percent: 17.4),
                MinimumPendingHandoffLedgerAdjuster(minimum: 41.1),
                RoundingPendingHandoffLedgerAdjuster(step: 0.05),
                CountryPendingHandoffLedgerAdjuster(factors: ["north": 0.96, "online": 1.06, "retail": 0.96]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 27761.9
        )
    }
}
