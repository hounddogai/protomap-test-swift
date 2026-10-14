import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback authorization assignment calculation.
    protocol FallbackAuthorizationAssignmentFactor {
        func describe() -> String
        func adjust(_ item: FallbackAuthorizationAssignment, value: Double) -> Double
    }

    final class FallbackAuthorizationAssignmentVisitMinutesOffsetAdjuster: FallbackAuthorizationAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: FallbackAuthorizationAssignment, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumFallbackAuthorizationAssignmentAdjuster: FallbackAuthorizationAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAuthorizationAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackAuthorizationAssignmentAdjuster: FallbackAuthorizationAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackAuthorizationAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackAuthorizationAssignmentAdjuster: FallbackAuthorizationAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAuthorizationAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackAuthorizationAssignmentAdjuster: FallbackAuthorizationAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAuthorizationAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback authorization assignment steps in order and keeps a trace of each.
    final class FallbackAuthorizationAssignmentEngine {
        var steps: [any FallbackAuthorizationAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAuthorizationAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackAuthorizationAssignment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAuthorizationAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackAuthorizationAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackAuthorizationAssignmentEngine() -> FallbackAuthorizationAssignmentEngine {
        return FallbackAuthorizationAssignmentEngine(
            steps: [
                FallbackAuthorizationAssignmentVisitMinutesOffsetAdjuster(weight: 0.44),
                MinimumFallbackAuthorizationAssignmentAdjuster(minimum: 32.4),
                PercentFallbackAuthorizationAssignmentAdjuster(percent: 2.1),
                RoundingFallbackAuthorizationAssignmentAdjuster(step: 5.0),
                CapFallbackAuthorizationAssignmentAdjuster(cap: 35891.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 99096.7
        )
    }
}
