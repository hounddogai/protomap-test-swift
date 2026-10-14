import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive claim template calculation.
    protocol AdaptiveClaimTemplateModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveClaimTemplate, value: Double) -> Double
    }

    final class CapAdaptiveClaimTemplateAdjuster: AdaptiveClaimTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveClaimTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAdaptiveClaimTemplateAdjuster: AdaptiveClaimTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveClaimTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveClaimTemplateAdjuster: AdaptiveClaimTemplateModifier {
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

        func adjust(_ item: AdaptiveClaimTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveClaimTemplateAdjuster: AdaptiveClaimTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveClaimTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive claim template steps in order and keeps a trace of each.
    final class AdaptiveClaimTemplateEngine {
        var steps: [any AdaptiveClaimTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveClaimTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveClaimTemplate) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [AdaptiveClaimTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveClaimTemplateEngine(_ flags: Kit.Flags.Registry) -> AdaptiveClaimTemplateEngine {
        return AdaptiveClaimTemplateEngine(
            steps: [
                CapAdaptiveClaimTemplateAdjuster(cap: 37832.0),
                TieredAdaptiveClaimTemplateAdjuster(bounds: [2775.0, 8265.0], rates: [0.99, 1.02]),
                FlaggedAdaptiveClaimTemplateAdjuster(
                    flags: flags,
                    flag: "adaptive-claim-template-lenient",
                    percent: -6.2
                ),
                PercentAdaptiveClaimTemplateAdjuster(percent: 9.4),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 44930.1
        )
    }
}
