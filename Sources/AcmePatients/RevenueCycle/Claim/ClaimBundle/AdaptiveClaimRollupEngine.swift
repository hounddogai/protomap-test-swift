import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive claim rollup calculation.
    protocol AdaptiveClaimRollupAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double
    }

    final class CapAdaptiveClaimRollupAdjuster: AdaptiveClaimRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveClaimRollupAdjuster: AdaptiveClaimRollupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveClaimRollupAdjuster: AdaptiveClaimRollupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleAdaptiveClaimRollupAdjuster: AdaptiveClaimRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveClaimRollupSequenceOffsetAdjuster: AdaptiveClaimRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingAdaptiveClaimRollupAdjuster: AdaptiveClaimRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveClaimRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive claim rollup steps in order and keeps a trace of each.
    final class AdaptiveClaimRollupEngine {
        var steps: [any AdaptiveClaimRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveClaimRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveClaimRollup) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveClaimRollupAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveClaimRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveClaimRollupEngine() -> AdaptiveClaimRollupEngine {
        return AdaptiveClaimRollupEngine(
            steps: [
                CapAdaptiveClaimRollupAdjuster(cap: 17960.0),
                PercentAdaptiveClaimRollupAdjuster(percent: -14.6),
                MinimumAdaptiveClaimRollupAdjuster(minimum: 44.6),
                LocaleAdaptiveClaimRollupAdjuster(factors: ["online": 1.06, "central": 1.22]),
                AdaptiveClaimRollupSequenceOffsetAdjuster(weight: 0.32),
                RoundingAdaptiveClaimRollupAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 14839.1
        )
    }
}
