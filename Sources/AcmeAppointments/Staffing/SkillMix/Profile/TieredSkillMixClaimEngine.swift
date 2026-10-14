import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered skill mix claim calculation.
    protocol ProfileTieredSkillMixClaimAdjuster {
        func describe() -> String
        func adjust(_ item: TieredSkillMixClaim, value: Double) -> Double
    }

    final class MinimumTieredSkillMixClaimAdjuster: ProfileTieredSkillMixClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredSkillMixClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredSkillMixClaimAdjuster: ProfileTieredSkillMixClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredSkillMixClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredSkillMixClaimAdjuster: ProfileTieredSkillMixClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredSkillMixClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered skill mix claim steps in order and keeps a trace of each.
    final class TieredSkillMixClaimEngine {
        var steps: [any ProfileTieredSkillMixClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProfileTieredSkillMixClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredSkillMixClaim) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [TieredSkillMixClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredSkillMixClaimEngine() -> TieredSkillMixClaimEngine {
        return TieredSkillMixClaimEngine(
            steps: [
                MinimumTieredSkillMixClaimAdjuster(minimum: 39.9),
                PercentTieredSkillMixClaimAdjuster(percent: 23.7),
                TieredTieredSkillMixClaimAdjuster(bounds: [275.0, 3176.0], rates: [1.07, 0.9]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 43024.5
        )
    }
}
