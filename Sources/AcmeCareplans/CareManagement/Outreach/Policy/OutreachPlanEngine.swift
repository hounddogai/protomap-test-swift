import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach plan calculation.
    protocol OutreachPlanStep {
        func describe() -> String
        func adjust(_ item: OutreachPlan, value: Double) -> Double
    }

    final class RoundingOutreachPlanAdjuster: OutreachPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapOutreachPlanAdjuster: OutreachPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumOutreachPlanAdjuster: OutreachPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class OutreachPlanBatchSizeOffsetAdjuster: OutreachPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: OutreachPlan, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the outreach plan steps in order and keeps a trace of each.
    final class OutreachPlanEngine {
        var steps: [any OutreachPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachPlan) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachPlanStep = steps[index]
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

        func evaluateAll(_ items: [OutreachPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachPlanEngine() -> OutreachPlanEngine {
        return OutreachPlanEngine(
            steps: [
                RoundingOutreachPlanAdjuster(step: 0.5),
                CapOutreachPlanAdjuster(cap: 6693.0),
                MinimumOutreachPlanAdjuster(minimum: 30.7),
                OutreachPlanBatchSizeOffsetAdjuster(weight: 0.25),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 87872.7
        )
    }
}
