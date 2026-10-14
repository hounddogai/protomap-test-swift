import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling slot threshold calculation.
    protocol RollingSlotThresholdStep {
        func describe() -> String
        func adjust(_ item: RollingSlotThreshold, value: Double) -> Double
    }

    final class TitleRollingSlotThresholdAdjuster: RollingSlotThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingSlotThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingSlotThresholdAdjuster: RollingSlotThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingSlotThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingSlotThresholdAdjuster: RollingSlotThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingSlotThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling slot threshold steps in order and keeps a trace of each.
    final class RollingSlotThresholdEngine {
        var steps: [any RollingSlotThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSlotThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingSlotThreshold) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [RollingSlotThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingSlotThresholdEngine() -> RollingSlotThresholdEngine {
        return RollingSlotThresholdEngine(
            steps: [
                TitleRollingSlotThresholdAdjuster(factors: ["central": 1.4, "west": 0.78]),
                PercentRollingSlotThresholdAdjuster(percent: 15.1),
                MinimumRollingSlotThresholdAdjuster(minimum: 23.5),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 40141.6
        )
    }
}
