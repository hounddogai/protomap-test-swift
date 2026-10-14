import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual charge assignment calculation.
    protocol ManualChargeAssignmentFactor {
        func describe() -> String
        func adjust(_ item: ManualChargeAssignment, value: Double) -> Double
    }

    final class RoundingManualChargeAssignmentAdjuster: ManualChargeAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualChargeAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ManualChargeAssignmentScoreOffsetAdjuster: ManualChargeAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ManualChargeAssignment, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapManualChargeAssignmentAdjuster: ManualChargeAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualChargeAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualChargeAssignmentAdjuster: ManualChargeAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualChargeAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual charge assignment steps in order and keeps a trace of each.
    final class ManualChargeAssignmentEngine {
        var steps: [any ManualChargeAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualChargeAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualChargeAssignment) -> Double {
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

        func evaluateAll(_ items: [ManualChargeAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualChargeAssignmentEngine() -> ManualChargeAssignmentEngine {
        return ManualChargeAssignmentEngine(
            steps: [
                RoundingManualChargeAssignmentAdjuster(step: 0.1),
                ManualChargeAssignmentScoreOffsetAdjuster(weight: 1.61),
                CapManualChargeAssignmentAdjuster(cap: 2013.0),
                PercentManualChargeAssignmentAdjuster(percent: -14.6),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 3355.8
        )
    }
}
