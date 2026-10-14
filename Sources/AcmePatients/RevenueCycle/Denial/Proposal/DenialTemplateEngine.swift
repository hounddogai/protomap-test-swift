import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial template calculation.
    protocol DenialTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: DenialTemplate, value: Double) -> Double
    }

    final class DenialTemplateExpiresAtOffsetAdjuster: DenialTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: DenialTemplate, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class FlaggedDenialTemplateAdjuster: DenialTemplateAdjuster {
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

        func adjust(_ item: DenialTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelDenialTemplateAdjuster: DenialTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: DenialTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the denial template steps in order and keeps a trace of each.
    final class DenialTemplateEngine {
        var steps: [any DenialTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialTemplate) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DenialTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialTemplateEngine(_ flags: Kit.Flags.Registry) -> DenialTemplateEngine {
        return DenialTemplateEngine(
            steps: [
                DenialTemplateExpiresAtOffsetAdjuster(weight: 1.65),
                FlaggedDenialTemplateAdjuster(flags: flags, flag: "denial-template-fallback", percent: 0.4),
                ChannelDenialTemplateAdjuster(factors: ["north": 1.33, "central": 1.32]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 60946.7
        )
    }
}
