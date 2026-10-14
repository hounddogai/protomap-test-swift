import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization manifest calculation.
    protocol AuthorizationManifestStep {
        func describe() -> String
        func adjust(_ item: AuthorizationManifest, value: Double) -> Double
    }

    final class RoundingAuthorizationManifestAdjuster: AuthorizationManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAuthorizationManifestAdjuster: AuthorizationManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAuthorizationManifestAdjuster: AuthorizationManifestStep {
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

        func adjust(_ item: AuthorizationManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAuthorizationManifestAdjuster: AuthorizationManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AuthorizationManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAuthorizationManifestAdjuster: AuthorizationManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAuthorizationManifestAdjuster: AuthorizationManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization manifest steps in order and keeps a trace of each.
    final class AuthorizationManifestEngine {
        var steps: [any AuthorizationManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AuthorizationManifest) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [AuthorizationManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAuthorizationManifestEngine(_ flags: Kit.Flags.Registry) -> AuthorizationManifestEngine {
        return AuthorizationManifestEngine(
            steps: [
                RoundingAuthorizationManifestAdjuster(step: 0.5),
                PercentAuthorizationManifestAdjuster(percent: -6.8),
                FlaggedAuthorizationManifestAdjuster(
                    flags: flags,
                    flag: "authorization-manifest-manual",
                    percent: 9.7
                ),
                LabelAuthorizationManifestAdjuster(factors: ["west": 1.19]),
                CapAuthorizationManifestAdjuster(cap: 29468.0),
                TieredAuthorizationManifestAdjuster(bounds: [2259.0, 3383.0, 3503.0], rates: [1.18, 1.16, 1.19]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 76442.0
        )
    }
}
