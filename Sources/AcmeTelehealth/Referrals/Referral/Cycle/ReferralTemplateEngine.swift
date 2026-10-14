import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral template calculation.
    protocol ReferralTemplateStep {
        func describe() -> String
        func adjust(_ item: ReferralTemplate, value: Double) -> Double
    }

    final class RoundingReferralTemplateAdjuster: ReferralTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferralTemplateAdjuster: ReferralTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReferralTemplateAdjuster: ReferralTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral template steps in order and keeps a trace of each.
    final class ReferralTemplateEngine {
        var steps: [any ReferralTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralTemplate) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralTemplateStep = steps[index]
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

        func evaluateAll(_ items: [ReferralTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralTemplateEngine() -> ReferralTemplateEngine {
        return ReferralTemplateEngine(
            steps: [
                RoundingReferralTemplateAdjuster(step: 1.0),
                PercentReferralTemplateAdjuster(percent: 1.3),
                TieredReferralTemplateAdjuster(bounds: [375.0, 411.0, 7542.0], rates: [0.96, 1.13, 1.15]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 72669.7
        )
    }
}
