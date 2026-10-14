import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback care protocol policy calculation.
    protocol FallbackCareProtocolPolicyFactor {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double
    }

    final class TieredFallbackCareProtocolPolicyAdjuster: FallbackCareProtocolPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackCareProtocolPolicyThresholdOffsetAdjuster: FallbackCareProtocolPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingFallbackCareProtocolPolicyAdjuster: FallbackCareProtocolPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackCareProtocolPolicyAdjuster: FallbackCareProtocolPolicyFactor {
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

        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackCareProtocolPolicyAdjuster: FallbackCareProtocolPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleFallbackCareProtocolPolicyAdjuster: FallbackCareProtocolPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackCareProtocolPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback care protocol policy steps in order and keeps a trace of each.
    final class FallbackCareProtocolPolicyEngine {
        var steps: [any FallbackCareProtocolPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackCareProtocolPolicy) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [FallbackCareProtocolPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolPolicyEngine(_ flags: Kit.Flags.Registry) -> FallbackCareProtocolPolicyEngine {
        return FallbackCareProtocolPolicyEngine(
            steps: [
                TieredFallbackCareProtocolPolicyAdjuster(bounds: [4930.0, 5137.0, 6009.0], rates: [1.03, 1.14, 1.13]),
                FallbackCareProtocolPolicyThresholdOffsetAdjuster(weight: 0.26),
                RoundingFallbackCareProtocolPolicyAdjuster(step: 1.0),
                FlaggedFallbackCareProtocolPolicyAdjuster(
                    flags: flags,
                    flag: "fallback-care-protocol-policy-global",
                    percent: 1.6
                ),
                MinimumFallbackCareProtocolPolicyAdjuster(minimum: 32.4),
                TitleFallbackCareProtocolPolicyAdjuster(factors: ["south": 0.74]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 23059.8
        )
    }
}
