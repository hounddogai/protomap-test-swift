import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist summary calculation.
    protocol WorklistSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistSummary, value: Double) -> Double
    }

    final class WorklistSummarySequenceOffsetAdjuster: WorklistSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: WorklistSummary, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TitleWorklistSummaryAdjuster: WorklistSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WorklistSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWorklistSummaryAdjuster: WorklistSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWorklistSummaryAdjuster: WorklistSummaryAdjuster {
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

        func adjust(_ item: WorklistSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the worklist summary steps in order and keeps a trace of each.
    final class WorklistSummaryEngine {
        var steps: [any WorklistSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WorklistSummary) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [WorklistSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWorklistSummaryEngine(_ flags: Kit.Flags.Registry) -> WorklistSummaryEngine {
        return WorklistSummaryEngine(
            steps: [
                WorklistSummarySequenceOffsetAdjuster(weight: 0.72),
                TitleWorklistSummaryAdjuster(factors: ["west": 0.83, "retail": 1.09]),
                PercentWorklistSummaryAdjuster(percent: 1.1),
                FlaggedWorklistSummaryAdjuster(flags: flags, flag: "worklist-summary-scheduled", percent: 3.9),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 84702.8
        )
    }
}
