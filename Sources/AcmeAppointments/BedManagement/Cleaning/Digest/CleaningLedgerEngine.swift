import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning ledger calculation.
    protocol CleaningLedgerStep {
        func describe() -> String
        func adjust(_ item: CleaningLedger, value: Double) -> Double
    }

    final class MinimumCleaningLedgerAdjuster: CleaningLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCleaningLedgerAdjuster: CleaningLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCleaningLedgerAdjuster: CleaningLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCleaningLedgerAdjuster: CleaningLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the cleaning ledger steps in order and keeps a trace of each.
    final class CleaningLedgerEngine {
        var steps: [any CleaningLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CleaningLedger) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [CleaningLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCleaningLedgerEngine() -> CleaningLedgerEngine {
        return CleaningLedgerEngine(
            steps: [
                MinimumCleaningLedgerAdjuster(minimum: 4.1),
                CapCleaningLedgerAdjuster(cap: 40801.0),
                PercentCleaningLedgerAdjuster(percent: 23.9),
                RoundingCleaningLedgerAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 9513.2
        )
    }
}
