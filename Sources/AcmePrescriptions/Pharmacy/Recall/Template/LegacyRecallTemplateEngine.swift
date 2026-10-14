import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy recall template calculation.
    protocol LegacyRecallTemplateStep {
        func describe() -> String
        func adjust(_ item: LegacyRecallTemplate, value: Double) -> Double
    }

    final class CapLegacyRecallTemplateAdjuster: LegacyRecallTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyRecallTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyRecallTemplateMinimumOffsetAdjuster: LegacyRecallTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LegacyRecallTemplate, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingLegacyRecallTemplateAdjuster: LegacyRecallTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyRecallTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyRecallTemplateAdjuster: LegacyRecallTemplateStep {
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

        func adjust(_ item: LegacyRecallTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy recall template steps in order and keeps a trace of each.
    final class LegacyRecallTemplateEngine {
        var steps: [any LegacyRecallTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRecallTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyRecallTemplate) -> Double {
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

        func evaluateAll(_ items: [LegacyRecallTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyRecallTemplateEngine(_ flags: Kit.Flags.Registry) -> LegacyRecallTemplateEngine {
        return LegacyRecallTemplateEngine(
            steps: [
                CapLegacyRecallTemplateAdjuster(cap: 48173.0),
                LegacyRecallTemplateMinimumOffsetAdjuster(weight: 1.69),
                RoundingLegacyRecallTemplateAdjuster(step: 5.0),
                FlaggedLegacyRecallTemplateAdjuster(
                    flags: flags,
                    flag: "legacy-recall-template-fallback",
                    percent: 2.5
                ),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 96229.6
        )
    }
}
