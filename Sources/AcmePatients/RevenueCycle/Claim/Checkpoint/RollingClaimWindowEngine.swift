import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling claim window calculation.
    protocol RollingClaimWindowFactor {
        func describe() -> String
        func adjust(_ item: RollingClaimWindow, value: Double) -> Double
    }

    final class RoundingRollingClaimWindowAdjuster: RollingClaimWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingClaimWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingClaimWindowAdjuster: RollingClaimWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingClaimWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingClaimWindowAdjuster: RollingClaimWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingClaimWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling claim window steps in order and keeps a trace of each.
    final class RollingClaimWindowEngine {
        var steps: [any RollingClaimWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClaimWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingClaimWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingClaimWindowFactor = steps[index]
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

        func evaluateAll(_ items: [RollingClaimWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingClaimWindowEngine() -> RollingClaimWindowEngine {
        return RollingClaimWindowEngine(
            steps: [
                RoundingRollingClaimWindowAdjuster(step: 0.25),
                MinimumRollingClaimWindowAdjuster(minimum: 11.6),
                PercentRollingClaimWindowAdjuster(percent: -23.1),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 19438.6
        )
    }
}
