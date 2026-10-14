import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient network score calculation.
    protocol LenientNetworkScoreAdjuster {
        func describe() -> String
        func adjust(_ item: LenientNetworkScore, value: Double) -> Double
    }

    final class MinimumLenientNetworkScoreAdjuster: LenientNetworkScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientNetworkScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLenientNetworkScoreAdjuster: LenientNetworkScoreAdjuster {
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

        func adjust(_ item: LenientNetworkScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientNetworkScoreAdjuster: LenientNetworkScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientNetworkScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientNetworkScoreAdjuster: LenientNetworkScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientNetworkScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLenientNetworkScoreAdjuster: LenientNetworkScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientNetworkScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelLenientNetworkScoreAdjuster: LenientNetworkScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientNetworkScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient network score steps in order and keeps a trace of each.
    final class LenientNetworkScoreEngine {
        var steps: [any LenientNetworkScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientNetworkScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientNetworkScore) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientNetworkScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientNetworkScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientNetworkScoreEngine(_ flags: Kit.Flags.Registry) -> LenientNetworkScoreEngine {
        return LenientNetworkScoreEngine(
            steps: [
                MinimumLenientNetworkScoreAdjuster(minimum: 34.9),
                FlaggedLenientNetworkScoreAdjuster(flags: flags, flag: "lenient-network-score-fallback", percent: 1.8),
                PercentLenientNetworkScoreAdjuster(percent: 10.2),
                CapLenientNetworkScoreAdjuster(cap: 14503.0),
                TieredLenientNetworkScoreAdjuster(bounds: [7257.0, 8819.0], rates: [1.03, 1.18]),
                LabelLenientNetworkScoreAdjuster(factors: ["retail": 1.14]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 57045.5
        )
    }
}
