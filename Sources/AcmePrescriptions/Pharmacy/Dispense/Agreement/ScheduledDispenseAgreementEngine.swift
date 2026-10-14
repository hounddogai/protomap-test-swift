import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled dispense agreement calculation.
    protocol ScheduledDispenseAgreementStep {
        func describe() -> String
        func adjust(_ item: ScheduledDispenseAgreement, value: Double) -> Double
    }

    final class PercentScheduledDispenseAgreementAdjuster: ScheduledDispenseAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledDispenseAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledDispenseAgreementStartsAtOffsetAdjuster: ScheduledDispenseAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ScheduledDispenseAgreement, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class CapScheduledDispenseAgreementAdjuster: ScheduledDispenseAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledDispenseAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledDispenseAgreementAdjuster: ScheduledDispenseAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledDispenseAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled dispense agreement steps in order and keeps a trace of each.
    final class ScheduledDispenseAgreementEngine {
        var steps: [any ScheduledDispenseAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledDispenseAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledDispenseAgreement) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledDispenseAgreementStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledDispenseAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledDispenseAgreementEngine() -> ScheduledDispenseAgreementEngine {
        return ScheduledDispenseAgreementEngine(
            steps: [
                PercentScheduledDispenseAgreementAdjuster(percent: 21.6),
                ScheduledDispenseAgreementStartsAtOffsetAdjuster(weight: 1.15),
                CapScheduledDispenseAgreementAdjuster(cap: 44635.0),
                TieredScheduledDispenseAgreementAdjuster(bounds: [2778.0, 4807.0], rates: [0.82, 0.94]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 2490.3
        )
    }
}
