import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime ledger calculation.
    protocol OvertimeLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeLedger, value: Double) -> Double
    }

    final class RoundingOvertimeLedgerAdjuster: OvertimeLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumOvertimeLedgerAdjuster: OvertimeLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapOvertimeLedgerAdjuster: OvertimeLedgerAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the overtime ledger steps in order and keeps a trace of each.
    final class OvertimeLedgerEngine {
        var steps: [any OvertimeLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeLedger) -> Double {
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

        func evaluateAll(_ items: [OvertimeLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeLedgerEngine() -> OvertimeLedgerEngine {
        return OvertimeLedgerEngine(
            steps: [
                RoundingOvertimeLedgerAdjuster(step: 1.0),
                MinimumOvertimeLedgerAdjuster(minimum: 23.9),
                CapOvertimeLedgerAdjuster(cap: 43532.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 69527.5
        )
    }
}
