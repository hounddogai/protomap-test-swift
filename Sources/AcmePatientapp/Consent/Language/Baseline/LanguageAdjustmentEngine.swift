import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language adjustment calculation.
    protocol LanguageAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: LanguageAdjustment, value: Double) -> Double
    }

    final class PercentLanguageAdjustmentAdjuster: LanguageAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLanguageAdjustmentAdjuster: LanguageAdjustmentModifier {
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

        func adjust(_ item: LanguageAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageAdjustmentAttemptsOffsetAdjuster: LanguageAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LanguageAdjustment, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the language adjustment steps in order and keeps a trace of each.
    final class LanguageAdjustmentEngine {
        var steps: [any LanguageAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LanguageAdjustment) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [LanguageAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLanguageAdjustmentEngine(_ flags: Kit.Flags.Registry) -> LanguageAdjustmentEngine {
        return LanguageAdjustmentEngine(
            steps: [
                PercentLanguageAdjustmentAdjuster(percent: 19.4),
                FlaggedLanguageAdjustmentAdjuster(flags: flags, flag: "language-adjustment-strict", percent: -8.3),
                LanguageAdjustmentAttemptsOffsetAdjuster(weight: 1.8),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 86930.3
        )
    }
}
