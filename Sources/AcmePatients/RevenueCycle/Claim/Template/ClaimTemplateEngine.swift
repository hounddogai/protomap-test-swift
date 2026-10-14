import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim template calculation.
    protocol ClaimTemplateFactor {
        func describe() -> String
        func adjust(_ item: ClaimTemplate, value: Double) -> Double
    }

    final class FlaggedClaimTemplateAdjuster: ClaimTemplateFactor {
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

        func adjust(_ item: ClaimTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentClaimTemplateAdjuster: ClaimTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardClaimTemplateAdjuster: ClaimTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ClaimTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingClaimTemplateAdjuster: ClaimTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim template steps in order and keeps a trace of each.
    final class ClaimTemplateEngine {
        var steps: [any ClaimTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClaimTemplate) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ClaimTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClaimTemplateEngine(_ flags: Kit.Flags.Registry) -> ClaimTemplateEngine {
        return ClaimTemplateEngine(
            steps: [
                FlaggedClaimTemplateAdjuster(flags: flags, flag: "claim-template-global", percent: -9.4),
                PercentClaimTemplateAdjuster(percent: 16.7),
                WardClaimTemplateAdjuster(factors: ["south": 0.93, "east": 1.24]),
                RoundingClaimTemplateAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 93161.4
        )
    }
}
