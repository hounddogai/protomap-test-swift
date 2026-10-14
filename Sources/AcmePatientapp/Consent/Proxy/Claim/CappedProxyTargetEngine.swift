import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped proxy target calculation.
    protocol CappedProxyTargetAdjuster {
        func describe() -> String
        func adjust(_ item: CappedProxyTarget, value: Double) -> Double
    }

    final class CappedProxyTargetDosageMgOffsetAdjuster: CappedProxyTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: CappedProxyTarget, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingCappedProxyTargetAdjuster: CappedProxyTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedProxyTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCappedProxyTargetAdjuster: CappedProxyTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedProxyTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped proxy target steps in order and keeps a trace of each.
    final class CappedProxyTargetEngine {
        var steps: [any CappedProxyTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedProxyTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedProxyTarget) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedProxyTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedProxyTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedProxyTargetEngine() -> CappedProxyTargetEngine {
        return CappedProxyTargetEngine(
            steps: [
                CappedProxyTargetDosageMgOffsetAdjuster(weight: 0.39),
                RoundingCappedProxyTargetAdjuster(step: 0.05),
                MinimumCappedProxyTargetAdjuster(minimum: 11.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 14768.5
        )
    }
}
