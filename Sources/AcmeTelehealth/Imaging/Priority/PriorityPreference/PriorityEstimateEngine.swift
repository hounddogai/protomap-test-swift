import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority estimate calculation.
    protocol PriorityEstimateStep {
        func describe() -> String
        func adjust(_ item: PriorityEstimate, value: Double) -> Double
    }

    final class PriorityEstimateCopayOffsetAdjuster: PriorityEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: PriorityEstimate, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapPriorityEstimateAdjuster: PriorityEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPriorityEstimateAdjuster: PriorityEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPriorityEstimateAdjuster: PriorityEstimateStep {
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

        func adjust(_ item: PriorityEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority estimate steps in order and keeps a trace of each.
    final class PriorityEstimateEngine {
        var steps: [any PriorityEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PriorityEstimate) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityEstimateStep = steps[index]
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

        func evaluateAll(_ items: [PriorityEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPriorityEstimateEngine(_ flags: Kit.Flags.Registry) -> PriorityEstimateEngine {
        return PriorityEstimateEngine(
            steps: [
                PriorityEstimateCopayOffsetAdjuster(weight: 1.96),
                CapPriorityEstimateAdjuster(cap: 4583.0),
                RoundingPriorityEstimateAdjuster(step: 1.0),
                FlaggedPriorityEstimateAdjuster(flags: flags, flag: "priority-estimate-batched", percent: 8.7),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 43812.6
        )
    }
}
