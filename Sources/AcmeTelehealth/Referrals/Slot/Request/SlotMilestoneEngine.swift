import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot milestone calculation.
    protocol SlotMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: SlotMilestone, value: Double) -> Double
    }

    final class RoundingSlotMilestoneAdjuster: SlotMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSlotMilestoneAdjuster: SlotMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SlotMilestoneMinimumOffsetAdjuster: SlotMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: SlotMilestone, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the slot milestone steps in order and keeps a trace of each.
    final class SlotMilestoneEngine {
        var steps: [any SlotMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotMilestone) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [SlotMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotMilestoneEngine() -> SlotMilestoneEngine {
        return SlotMilestoneEngine(
            steps: [
                RoundingSlotMilestoneAdjuster(step: 5.0),
                CapSlotMilestoneAdjuster(cap: 28691.0),
                SlotMilestoneMinimumOffsetAdjuster(weight: 1.85),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 88337.6
        )
    }
}
