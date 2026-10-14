import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled transfer profile calculation.
    protocol ScheduledTransferProfileStep {
        func describe() -> String
        func adjust(_ item: ScheduledTransferProfile, value: Double) -> Double
    }

    final class TieredScheduledTransferProfileAdjuster: ScheduledTransferProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledTransferProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentScheduledTransferProfileAdjuster: ScheduledTransferProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledTransferProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledTransferProfileAdjuster: ScheduledTransferProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledTransferProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled transfer profile steps in order and keeps a trace of each.
    final class ScheduledTransferProfileEngine {
        var steps: [any ScheduledTransferProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledTransferProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledTransferProfile) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledTransferProfileStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledTransferProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledTransferProfileEngine() -> ScheduledTransferProfileEngine {
        return ScheduledTransferProfileEngine(
            steps: [
                TieredScheduledTransferProfileAdjuster(
                    bounds: [2654.0, 2921.0, 3194.0, 5974.0],
                    rates: [0.98, 1.02, 0.87, 1.07]
                ),
                PercentScheduledTransferProfileAdjuster(percent: -12.0),
                RoundingScheduledTransferProfileAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 78167.9
        )
    }
}
