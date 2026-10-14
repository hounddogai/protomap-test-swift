import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped bed board reservation calculation.
    protocol CappedBedBoardReservationAdjuster {
        func describe() -> String
        func adjust(_ item: CappedBedBoardReservation, value: Double) -> Double
    }

    final class CappedBedBoardReservationRefillsOffsetAdjuster: CappedBedBoardReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: CappedBedBoardReservation, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class PercentCappedBedBoardReservationAdjuster: CappedBedBoardReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedBedBoardReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedBedBoardReservationAdjuster: CappedBedBoardReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedBedBoardReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped bed board reservation steps in order and keeps a trace of each.
    final class CappedBedBoardReservationEngine {
        var steps: [any CappedBedBoardReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedBedBoardReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedBedBoardReservation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedBedBoardReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedBedBoardReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedBedBoardReservationEngine() -> CappedBedBoardReservationEngine {
        return CappedBedBoardReservationEngine(
            steps: [
                CappedBedBoardReservationRefillsOffsetAdjuster(weight: 0.51),
                PercentCappedBedBoardReservationAdjuster(percent: -19.1),
                RoundingCappedBedBoardReservationAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 30675.6
        )
    }
}
