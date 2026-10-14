import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled study reservation calculation.
    protocol ScheduledStudyReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledStudyReservation, value: Double) -> Double
    }

    final class MinimumScheduledStudyReservationAdjuster: ScheduledStudyReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledStudyReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceScheduledStudyReservationAdjuster: ScheduledStudyReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ScheduledStudyReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledStudyReservationAdjuster: ScheduledStudyReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledStudyReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledStudyReservationAdjuster: ScheduledStudyReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledStudyReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ScheduledStudyReservationEndsAtOffsetAdjuster: ScheduledStudyReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ScheduledStudyReservation, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the scheduled study reservation steps in order and keeps a trace of each.
    final class ScheduledStudyReservationEngine {
        var steps: [any ScheduledStudyReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledStudyReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledStudyReservation) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledStudyReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledStudyReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledStudyReservationEngine() -> ScheduledStudyReservationEngine {
        return ScheduledStudyReservationEngine(
            steps: [
                MinimumScheduledStudyReservationAdjuster(minimum: 49.2),
                SourceScheduledStudyReservationAdjuster(factors: ["east": 0.75]),
                PercentScheduledStudyReservationAdjuster(percent: 12.1),
                RoundingScheduledStudyReservationAdjuster(step: 5.0),
                ScheduledStudyReservationEndsAtOffsetAdjuster(weight: 1.37),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 1588.5
        )
    }
}
