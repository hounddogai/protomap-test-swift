import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness schedule calculation.
    protocol WitnessScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: WitnessSchedule, value: Double) -> Double
    }

    final class MinimumWitnessScheduleAdjuster: WitnessScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleWitnessScheduleAdjuster: WitnessScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: WitnessSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WitnessScheduleRefillsOffsetAdjuster: WitnessScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: WitnessSchedule, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapWitnessScheduleAdjuster: WitnessScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWitnessScheduleAdjuster: WitnessScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the witness schedule steps in order and keeps a trace of each.
    final class WitnessScheduleEngine {
        var steps: [any WitnessScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessSchedule) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessScheduleAdjuster = steps[index]
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

        func evaluateAll(_ items: [WitnessSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessScheduleEngine() -> WitnessScheduleEngine {
        return WitnessScheduleEngine(
            steps: [
                MinimumWitnessScheduleAdjuster(minimum: 19.8),
                LocaleWitnessScheduleAdjuster(factors: ["online": 1.2, "north": 1.17]),
                WitnessScheduleRefillsOffsetAdjuster(weight: 1.92),
                CapWitnessScheduleAdjuster(cap: 38960.0),
                TieredWitnessScheduleAdjuster(bounds: [2578.0, 5066.0], rates: [1.11, 0.97]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 30633.8
        )
    }
}
