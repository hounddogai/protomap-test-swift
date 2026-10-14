import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential rollup calculation.
    protocol CredentialRollupStep {
        func describe() -> String
        func adjust(_ item: CredentialRollup, value: Double) -> Double
    }

    final class PercentCredentialRollupAdjuster: CredentialRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCredentialRollupAdjuster: CredentialRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCredentialRollupAdjuster: CredentialRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CredentialRollupRefillsOffsetAdjuster: CredentialRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: CredentialRollup, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class FlaggedCredentialRollupAdjuster: CredentialRollupStep {
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

        func adjust(_ item: CredentialRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleCredentialRollupAdjuster: CredentialRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CredentialRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential rollup steps in order and keeps a trace of each.
    final class CredentialRollupEngine {
        var steps: [any CredentialRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CredentialRollup) -> Double {
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

        func evaluateAll(_ items: [CredentialRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCredentialRollupEngine(_ flags: Kit.Flags.Registry) -> CredentialRollupEngine {
        return CredentialRollupEngine(
            steps: [
                PercentCredentialRollupAdjuster(percent: -5.0),
                RoundingCredentialRollupAdjuster(step: 1.0),
                TieredCredentialRollupAdjuster(bounds: [2365.0, 4923.0, 5356.0], rates: [0.99, 1.1, 0.99]),
                CredentialRollupRefillsOffsetAdjuster(weight: 1.0),
                FlaggedCredentialRollupAdjuster(flags: flags, flag: "credential-rollup-weighted", percent: -0.4),
                LocaleCredentialRollupAdjuster(factors: ["west": 1.28, "east": 1.19]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 95592.3
        )
    }
}
