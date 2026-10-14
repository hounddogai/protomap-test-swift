import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback goal claim calculation.
    protocol FallbackGoalClaimModifier {
        func describe() -> String
        func adjust(_ item: FallbackGoalClaim, value: Double) -> Double
    }

    final class TieredFallbackGoalClaimAdjuster: FallbackGoalClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackGoalClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackGoalClaimAdjuster: FallbackGoalClaimModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FallbackGoalClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackGoalClaimAdjuster: FallbackGoalClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackGoalClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackGoalClaimAdjuster: FallbackGoalClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackGoalClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback goal claim steps in order and keeps a trace of each.
    final class FallbackGoalClaimEngine {
        var steps: [any FallbackGoalClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackGoalClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackGoalClaim) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [FallbackGoalClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackGoalClaimEngine(_ flags: Kit.Flags.Registry) -> FallbackGoalClaimEngine {
        return FallbackGoalClaimEngine(
            steps: [
                TieredFallbackGoalClaimAdjuster(bounds: [5517.0, 7035.0, 7634.0], rates: [1.06, 1.0, 0.9]),
                FlaggedFallbackGoalClaimAdjuster(flags: flags, flag: "fallback-goal-claim-pending", percent: 1.3),
                RoundingFallbackGoalClaimAdjuster(step: 0.25),
                MinimumFallbackGoalClaimAdjuster(minimum: 40.3),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 49149.9
        )
    }
}
