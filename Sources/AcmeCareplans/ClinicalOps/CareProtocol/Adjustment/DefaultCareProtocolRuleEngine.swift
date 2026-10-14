import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default care protocol rule calculation.
    protocol DefaultCareProtocolRuleStep {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolRule, value: Double) -> Double
    }

    final class DefaultCareProtocolRuleVisitMinutesOffsetAdjuster: DefaultCareProtocolRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: DefaultCareProtocolRule, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class TieredDefaultCareProtocolRuleAdjuster: DefaultCareProtocolRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareProtocolRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultCareProtocolRuleAdjuster: DefaultCareProtocolRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCareProtocolRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default care protocol rule steps in order and keeps a trace of each.
    final class DefaultCareProtocolRuleEngine {
        var steps: [any DefaultCareProtocolRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultCareProtocolRule) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCareProtocolRuleStep = steps[index]
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

        func evaluateAll(_ items: [DefaultCareProtocolRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolRuleEngine() -> DefaultCareProtocolRuleEngine {
        return DefaultCareProtocolRuleEngine(
            steps: [
                DefaultCareProtocolRuleVisitMinutesOffsetAdjuster(weight: 0.99),
                TieredDefaultCareProtocolRuleAdjuster(bounds: [3954.0, 5538.0, 5915.0], rates: [0.99, 0.96, 1.16]),
                PercentDefaultCareProtocolRuleAdjuster(percent: 23.7),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 61326.4
        )
    }
}
