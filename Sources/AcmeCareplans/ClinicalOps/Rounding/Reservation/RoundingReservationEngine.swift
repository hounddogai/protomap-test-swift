import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding reservation calculation.
    protocol RoundingReservationAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingReservation, value: Double) -> Double
    }

    final class RoundingRoundingReservationAdjuster: RoundingReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRoundingReservationAdjuster: RoundingReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRoundingReservationAdjuster: RoundingReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rounding reservation steps in order and keeps a trace of each.
    final class RoundingReservationEngine {
        var steps: [any RoundingReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingReservation) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [RoundingReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingReservationEngine() -> RoundingReservationEngine {
        return RoundingReservationEngine(
            steps: [
                RoundingRoundingReservationAdjuster(step: 0.1),
                PercentRoundingReservationAdjuster(percent: 13.2),
                CapRoundingReservationAdjuster(cap: 13232.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 71006.7
        )
    }
}
