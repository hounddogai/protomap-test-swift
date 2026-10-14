import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program reservation calculation.
    protocol ProgramReservationFactor {
        func describe() -> String
        func adjust(_ item: ProgramReservation, value: Double) -> Double
    }

    final class PercentProgramReservationAdjuster: ProgramReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProgramReservationAdjuster: ProgramReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredProgramReservationAdjuster: ProgramReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingProgramReservationAdjuster: ProgramReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ProgramReservationCeilingOffsetAdjuster: ProgramReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ProgramReservation, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the program reservation steps in order and keeps a trace of each.
    final class ProgramReservationEngine {
        var steps: [any ProgramReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramReservationFactor = steps[index]
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

        func evaluateAll(_ items: [ProgramReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramReservationEngine() -> ProgramReservationEngine {
        return ProgramReservationEngine(
            steps: [
                PercentProgramReservationAdjuster(percent: -7.8),
                CapProgramReservationAdjuster(cap: 46073.0),
                TieredProgramReservationAdjuster(bounds: [4789.0, 5755.0, 6933.0], rates: [0.99, 0.8, 1.02]),
                RoundingProgramReservationAdjuster(step: 0.05),
                ProgramReservationCeilingOffsetAdjuster(weight: 0.42),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 89251.1
        )
    }
}
