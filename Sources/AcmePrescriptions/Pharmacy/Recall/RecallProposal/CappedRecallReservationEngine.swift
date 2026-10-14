import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped recall reservation calculation.
    protocol CappedRecallReservationAdjuster {
        func describe() -> String
        func adjust(_ item: CappedRecallReservation, value: Double) -> Double
    }

    final class PercentCappedRecallReservationAdjuster: CappedRecallReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedRecallReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedRecallReservationThresholdOffsetAdjuster: CappedRecallReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: CappedRecallReservation, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumCappedRecallReservationAdjuster: CappedRecallReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedRecallReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped recall reservation steps in order and keeps a trace of each.
    final class CappedRecallReservationEngine {
        var steps: [any CappedRecallReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRecallReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedRecallReservation) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedRecallReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedRecallReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedRecallReservationEngine() -> CappedRecallReservationEngine {
        return CappedRecallReservationEngine(
            steps: [
                PercentCappedRecallReservationAdjuster(percent: 19.7),
                CappedRecallReservationThresholdOffsetAdjuster(weight: 0.55),
                MinimumCappedRecallReservationAdjuster(minimum: 46.7),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 80989.3
        )
    }
}
