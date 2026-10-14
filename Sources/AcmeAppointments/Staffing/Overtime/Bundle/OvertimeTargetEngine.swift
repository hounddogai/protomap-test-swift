import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime target calculation.
    protocol OvertimeTargetFactor {
        func describe() -> String
        func adjust(_ item: OvertimeTarget, value: Double) -> Double
    }

    final class PercentOvertimeTargetAdjuster: OvertimeTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOvertimeTargetAdjuster: OvertimeTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class OvertimeTargetFloorValueOffsetAdjuster: OvertimeTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: OvertimeTarget, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the overtime target steps in order and keeps a trace of each.
    final class OvertimeTargetEngine {
        var steps: [any OvertimeTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeTarget) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeTargetFactor = steps[index]
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

        func evaluateAll(_ items: [OvertimeTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeTargetEngine() -> OvertimeTargetEngine {
        return OvertimeTargetEngine(
            steps: [
                PercentOvertimeTargetAdjuster(percent: -20.1),
                CapOvertimeTargetAdjuster(cap: 40778.0),
                OvertimeTargetFloorValueOffsetAdjuster(weight: 1.37),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 55498.5
        )
    }
}
