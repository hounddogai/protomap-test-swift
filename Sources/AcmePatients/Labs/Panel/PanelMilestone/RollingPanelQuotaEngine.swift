import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling panel quota calculation.
    protocol RollingPanelQuotaFactor {
        func describe() -> String
        func adjust(_ item: RollingPanelQuota, value: Double) -> Double
    }

    final class TieredRollingPanelQuotaAdjuster: RollingPanelQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingPanelQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingPanelQuotaThresholdOffsetAdjuster: RollingPanelQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: RollingPanelQuota, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumRollingPanelQuotaAdjuster: RollingPanelQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingPanelQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling panel quota steps in order and keeps a trace of each.
    final class RollingPanelQuotaEngine {
        var steps: [any RollingPanelQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPanelQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingPanelQuota) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingPanelQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [RollingPanelQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingPanelQuotaEngine() -> RollingPanelQuotaEngine {
        return RollingPanelQuotaEngine(
            steps: [
                TieredRollingPanelQuotaAdjuster(bounds: [2590.0, 7276.0], rates: [0.93, 1.04]),
                RollingPanelQuotaThresholdOffsetAdjuster(weight: 1.55),
                MinimumRollingPanelQuotaAdjuster(minimum: 1.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 4683.6
        )
    }
}
