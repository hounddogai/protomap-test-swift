import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered worklist estimate calculation.
    protocol TieredWorklistEstimateModifier {
        func describe() -> String
        func adjust(_ item: TieredWorklistEstimate, value: Double) -> Double
    }

    final class CapTieredWorklistEstimateAdjuster: TieredWorklistEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredWorklistEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredWorklistEstimateAdjuster: TieredWorklistEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredWorklistEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWorklistEstimateDurationMinutesOffsetAdjuster: TieredWorklistEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: TieredWorklistEstimate, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedTieredWorklistEstimateAdjuster: TieredWorklistEstimateModifier {
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

        func adjust(_ item: TieredWorklistEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered worklist estimate steps in order and keeps a trace of each.
    final class TieredWorklistEstimateEngine {
        var steps: [any TieredWorklistEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredWorklistEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredWorklistEstimate) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredWorklistEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [TieredWorklistEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredWorklistEstimateEngine(_ flags: Kit.Flags.Registry) -> TieredWorklistEstimateEngine {
        return TieredWorklistEstimateEngine(
            steps: [
                CapTieredWorklistEstimateAdjuster(cap: 19405.0),
                MinimumTieredWorklistEstimateAdjuster(minimum: 18.0),
                TieredWorklistEstimateDurationMinutesOffsetAdjuster(weight: 0.59),
                FlaggedTieredWorklistEstimateAdjuster(
                    flags: flags,
                    flag: "tiered-worklist-estimate-lenient",
                    percent: 0.3
                ),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 55693.2
        )
    }
}
