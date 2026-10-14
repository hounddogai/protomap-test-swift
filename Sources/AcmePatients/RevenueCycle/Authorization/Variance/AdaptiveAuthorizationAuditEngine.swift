import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive authorization audit calculation.
    protocol AdaptiveAuthorizationAuditStep {
        func describe() -> String
        func adjust(_ item: AdaptiveAuthorizationAudit, value: Double) -> Double
    }

    final class TieredAdaptiveAuthorizationAuditAdjuster: AdaptiveAuthorizationAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveAuthorizationAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceAdaptiveAuthorizationAuditAdjuster: AdaptiveAuthorizationAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AdaptiveAuthorizationAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAdaptiveAuthorizationAuditAdjuster: AdaptiveAuthorizationAuditStep {
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

        func adjust(_ item: AdaptiveAuthorizationAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveAuthorizationAuditAdjuster: AdaptiveAuthorizationAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveAuthorizationAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveAuthorizationAuditAdjuster: AdaptiveAuthorizationAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveAuthorizationAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive authorization audit steps in order and keeps a trace of each.
    final class AdaptiveAuthorizationAuditEngine {
        var steps: [any AdaptiveAuthorizationAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAuthorizationAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveAuthorizationAudit) -> Double {
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

        func evaluateAll(_ items: [AdaptiveAuthorizationAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAuthorizationAuditEngine(_ flags: Kit.Flags.Registry) -> AdaptiveAuthorizationAuditEngine {
        return AdaptiveAuthorizationAuditEngine(
            steps: [
                TieredAdaptiveAuthorizationAuditAdjuster(
                    bounds: [2555.0, 3501.0, 5346.0, 8471.0],
                    rates: [1.15, 0.96, 0.94, 1.04]
                ),
                SourceAdaptiveAuthorizationAuditAdjuster(factors: ["online": 1.05, "south": 0.84, "east": 1.14]),
                FlaggedAdaptiveAuthorizationAuditAdjuster(
                    flags: flags,
                    flag: "adaptive-authorization-audit-capped",
                    percent: 3.2
                ),
                PercentAdaptiveAuthorizationAuditAdjuster(percent: 1.1),
                MinimumAdaptiveAuthorizationAuditAdjuster(minimum: 6.1),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 2550.5
        )
    }
}
