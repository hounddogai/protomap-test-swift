import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer reservation calculation.
    protocol TransferReservationModifier {
        func describe() -> String
        func adjust(_ item: TransferReservation, value: Double) -> Double
    }

    final class CountryTransferReservationAdjuster: TransferReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TransferReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTransferReservationAdjuster: TransferReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTransferReservationAdjuster: TransferReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the transfer reservation steps in order and keeps a trace of each.
    final class TransferReservationEngine {
        var steps: [any TransferReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferReservation) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [TransferReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferReservationEngine() -> TransferReservationEngine {
        return TransferReservationEngine(
            steps: [
                CountryTransferReservationAdjuster(factors: ["west": 1.25]),
                RoundingTransferReservationAdjuster(step: 5.0),
                CapTransferReservationAdjuster(cap: 19931.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 56261.7
        )
    }
}
