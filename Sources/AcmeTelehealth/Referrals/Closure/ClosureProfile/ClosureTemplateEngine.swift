import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure template calculation.
    protocol ClosureTemplateModifier {
        func describe() -> String
        func adjust(_ item: ClosureTemplate, value: Double) -> Double
    }

    final class ClosureTemplateVisitMinutesOffsetAdjuster: ClosureTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ClosureTemplate, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedClosureTemplateAdjuster: ClosureTemplateModifier {
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

        func adjust(_ item: ClosureTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClosureTemplateAdjuster: ClosureTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the closure template steps in order and keeps a trace of each.
    final class ClosureTemplateEngine {
        var steps: [any ClosureTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureTemplate) -> Double {
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

        func evaluateAll(_ items: [ClosureTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureTemplateEngine(_ flags: Kit.Flags.Registry) -> ClosureTemplateEngine {
        return ClosureTemplateEngine(
            steps: [
                ClosureTemplateVisitMinutesOffsetAdjuster(weight: 1.81),
                FlaggedClosureTemplateAdjuster(flags: flags, flag: "closure-template-manual", percent: 6.8),
                MinimumClosureTemplateAdjuster(minimum: 29.2),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 73845.4
        )
    }
}
