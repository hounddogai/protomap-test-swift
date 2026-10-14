import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback outreach assignment calculation.
    protocol FallbackOutreachAssignmentModifier {
        func describe() -> String
        func adjust(_ item: FallbackOutreachAssignment, value: Double) -> Double
    }

    final class PercentFallbackOutreachAssignmentAdjuster: FallbackOutreachAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackOutreachAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackOutreachAssignmentAdjuster: FallbackOutreachAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackOutreachAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackOutreachAssignmentAcuityOffsetAdjuster: FallbackOutreachAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: FallbackOutreachAssignment, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class MinimumFallbackOutreachAssignmentAdjuster: FallbackOutreachAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackOutreachAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback outreach assignment steps in order and keeps a trace of each.
    final class FallbackOutreachAssignmentEngine {
        var steps: [any FallbackOutreachAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackOutreachAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackOutreachAssignment) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackOutreachAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackOutreachAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackOutreachAssignmentEngine() -> FallbackOutreachAssignmentEngine {
        return FallbackOutreachAssignmentEngine(
            steps: [
                PercentFallbackOutreachAssignmentAdjuster(percent: -4.3),
                CapFallbackOutreachAssignmentAdjuster(cap: 41718.0),
                FallbackOutreachAssignmentAcuityOffsetAdjuster(weight: 0.09),
                MinimumFallbackOutreachAssignmentAdjuster(minimum: 37.4),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 68883.2
        )
    }
}
