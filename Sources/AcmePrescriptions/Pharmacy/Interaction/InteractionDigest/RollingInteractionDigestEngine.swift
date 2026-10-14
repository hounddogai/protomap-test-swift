import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling interaction digest calculation.
    protocol RollingInteractionDigestAdjuster {
        func describe() -> String
        func adjust(_ item: RollingInteractionDigest, value: Double) -> Double
    }

    final class MinimumRollingInteractionDigestAdjuster: RollingInteractionDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingInteractionDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RollingInteractionDigestMaximumOffsetAdjuster: RollingInteractionDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RollingInteractionDigest, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class RoundingRollingInteractionDigestAdjuster: RollingInteractionDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingInteractionDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling interaction digest steps in order and keeps a trace of each.
    final class RollingInteractionDigestEngine {
        var steps: [any RollingInteractionDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingInteractionDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingInteractionDigest) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [RollingInteractionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingInteractionDigestEngine() -> RollingInteractionDigestEngine {
        return RollingInteractionDigestEngine(
            steps: [
                MinimumRollingInteractionDigestAdjuster(minimum: 39.4),
                RollingInteractionDigestMaximumOffsetAdjuster(weight: 1.85),
                RoundingRollingInteractionDigestAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 39771.0
        )
    }
}
