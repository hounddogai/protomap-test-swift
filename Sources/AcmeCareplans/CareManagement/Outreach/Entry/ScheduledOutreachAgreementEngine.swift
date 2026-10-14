import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled outreach agreement calculation.
    protocol ScheduledOutreachAgreementStep {
        func describe() -> String
        func adjust(_ item: ScheduledOutreachAgreement, value: Double) -> Double
    }

    final class TieredScheduledOutreachAgreementAdjuster: ScheduledOutreachAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledOutreachAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledOutreachAgreementAdjuster: ScheduledOutreachAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledOutreachAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledOutreachAgreementAdjuster: ScheduledOutreachAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledOutreachAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledOutreachAgreementAdjuster: ScheduledOutreachAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledOutreachAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled outreach agreement steps in order and keeps a trace of each.
    final class ScheduledOutreachAgreementEngine {
        var steps: [any ScheduledOutreachAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledOutreachAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledOutreachAgreement) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [ScheduledOutreachAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledOutreachAgreementEngine() -> ScheduledOutreachAgreementEngine {
        return ScheduledOutreachAgreementEngine(
            steps: [
                TieredScheduledOutreachAgreementAdjuster(bounds: [6408.0, 8481.0, 9706.0], rates: [1.16, 1.03, 1.19]),
                CapScheduledOutreachAgreementAdjuster(cap: 37572.0),
                MinimumScheduledOutreachAgreementAdjuster(minimum: 39.6),
                RoundingScheduledOutreachAgreementAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 30409.2
        )
    }
}
