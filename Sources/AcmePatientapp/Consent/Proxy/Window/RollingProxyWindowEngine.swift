import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling proxy window calculation.
    protocol RollingProxyWindowFactor {
        func describe() -> String
        func adjust(_ item: RollingProxyWindow, value: Double) -> Double
    }

    final class PercentRollingProxyWindowAdjuster: RollingProxyWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingProxyWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingProxyWindowAmountOffsetAdjuster: RollingProxyWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RollingProxyWindow, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapRollingProxyWindowAdjuster: RollingProxyWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingProxyWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingProxyWindowAdjuster: RollingProxyWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingProxyWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingProxyWindowAdjuster: RollingProxyWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingProxyWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling proxy window steps in order and keeps a trace of each.
    final class RollingProxyWindowEngine {
        var steps: [any RollingProxyWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingProxyWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingProxyWindow) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RollingProxyWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingProxyWindowEngine() -> RollingProxyWindowEngine {
        return RollingProxyWindowEngine(
            steps: [
                PercentRollingProxyWindowAdjuster(percent: -0.3),
                RollingProxyWindowAmountOffsetAdjuster(weight: 1.83),
                CapRollingProxyWindowAdjuster(cap: 23147.0),
                RoundingRollingProxyWindowAdjuster(step: 0.5),
                MinimumRollingProxyWindowAdjuster(minimum: 25.1),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 57181.7
        )
    }
}
