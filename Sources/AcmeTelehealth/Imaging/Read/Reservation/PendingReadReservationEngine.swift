import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending read reservation calculation.
    protocol PendingReadReservationAdjuster {
        func describe() -> String
        func adjust(_ item: PendingReadReservation, value: Double) -> Double
    }

    final class CapPendingReadReservationAdjuster: PendingReadReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingReadReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingReadReservationAdjuster: PendingReadReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingReadReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingReadReservationAdjuster: PendingReadReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingReadReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelPendingReadReservationAdjuster: PendingReadReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingReadReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending read reservation steps in order and keeps a trace of each.
    final class PendingReadReservationEngine {
        var steps: [any PendingReadReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingReadReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingReadReservation) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingReadReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingReadReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingReadReservationEngine() -> PendingReadReservationEngine {
        return PendingReadReservationEngine(
            steps: [
                CapPendingReadReservationAdjuster(cap: 17900.0),
                PercentPendingReadReservationAdjuster(percent: 6.4),
                MinimumPendingReadReservationAdjuster(minimum: 21.0),
                LabelPendingReadReservationAdjuster(factors: ["north": 1.09, "south": 1.27]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 79605.9
        )
    }
}
