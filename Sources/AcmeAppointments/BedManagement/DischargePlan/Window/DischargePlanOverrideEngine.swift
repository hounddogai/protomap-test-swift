import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan override calculation.
    protocol DischargePlanOverrideModifier {
        func describe() -> String
        func adjust(_ item: DischargePlanOverride, value: Double) -> Double
    }

    final class CapDischargePlanOverrideAdjuster: DischargePlanOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDischargePlanOverrideAdjuster: DischargePlanOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DischargePlanOverrideRefillsOffsetAdjuster: DischargePlanOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: DischargePlanOverride, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the discharge plan override steps in order and keeps a trace of each.
    final class DischargePlanOverrideEngine {
        var steps: [any DischargePlanOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanOverride) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [DischargePlanOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanOverrideEngine() -> DischargePlanOverrideEngine {
        return DischargePlanOverrideEngine(
            steps: [
                CapDischargePlanOverrideAdjuster(cap: 49324.0),
                PercentDischargePlanOverrideAdjuster(percent: -16.7),
                DischargePlanOverrideRefillsOffsetAdjuster(weight: 0.52),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 86591.2
        )
    }
}
