import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach policy calculation.
    protocol OutreachPolicyFactor {
        func describe() -> String
        func adjust(_ item: OutreachPolicy, value: Double) -> Double
    }

    final class TieredOutreachPolicyAdjuster: OutreachPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumOutreachPolicyAdjuster: OutreachPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOutreachPolicyAdjuster: OutreachPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OutreachPolicyWindowDaysOffsetAdjuster: OutreachPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: OutreachPolicy, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RegionOutreachPolicyAdjuster: OutreachPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: OutreachPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the outreach policy steps in order and keeps a trace of each.
    final class OutreachPolicyEngine {
        var steps: [any OutreachPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachPolicy) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [OutreachPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachPolicyEngine() -> OutreachPolicyEngine {
        return OutreachPolicyEngine(
            steps: [
                TieredOutreachPolicyAdjuster(bounds: [64.0, 2742.0, 2986.0, 8888.0], rates: [0.96, 1.15, 0.95, 1.02]),
                MinimumOutreachPolicyAdjuster(minimum: 21.5),
                RoundingOutreachPolicyAdjuster(step: 1.0),
                OutreachPolicyWindowDaysOffsetAdjuster(weight: 0.96),
                RegionOutreachPolicyAdjuster(factors: ["online": 1.28, "west": 0.74]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 97118.8
        )
    }
}
