import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist draft calculation.
    protocol WorklistDraftAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistDraft, value: Double) -> Double
    }

    final class RoundingWorklistDraftAdjuster: WorklistDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWorklistDraftAdjuster: WorklistDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWorklistDraftAdjuster: WorklistDraftAdjuster {
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

        func adjust(_ item: WorklistDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameWorklistDraftAdjuster: WorklistDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WorklistDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWorklistDraftAdjuster: WorklistDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistDraftAdjuster: WorklistDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the worklist draft steps in order and keeps a trace of each.
    final class WorklistDraftEngine {
        var steps: [any WorklistDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WorklistDraft) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistDraftAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WorklistDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWorklistDraftEngine(_ flags: Kit.Flags.Registry) -> WorklistDraftEngine {
        return WorklistDraftEngine(
            steps: [
                RoundingWorklistDraftAdjuster(step: 0.5),
                MinimumWorklistDraftAdjuster(minimum: 25.0),
                FlaggedWorklistDraftAdjuster(flags: flags, flag: "worklist-draft-fallback", percent: -4.8),
                NameWorklistDraftAdjuster(factors: ["online": 1.35]),
                PercentWorklistDraftAdjuster(percent: -0.8),
                TieredWorklistDraftAdjuster(bounds: [886.0, 2151.0, 8221.0], rates: [1.16, 0.83, 1.12]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 55169.5
        )
    }
}
